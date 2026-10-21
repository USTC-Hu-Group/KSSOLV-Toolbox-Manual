% Same-material 2-D stacking and exact water/ethanol mixture construction.
% MATLAB source-mode checks only; no GUI, DFT, or molecular equilibration.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
diary(fullfile(outputDirectory, 'interface-packing-examples.log'));
diaryCleanup = onCleanup(@() diary('off'));
fprintf('MATLAB %s; JVM %d; %s\n', version, usejava('jvm'), computer('arch'));
report = struct('mode', 'MATLAB-source-nojvm', 'MATLAB', version, ...
    'JVM', usejava('jvm'), 'GUIOperated', false, 'DFTCalculation', false);

%% A two-site graphene layer: use the repository's existing test geometry.
lattice = kssolv.analysis.matgenlab.core.Lattice.hexagonal( ...
    2.46, 15, pbc=[true true false]);
layer = kssolv.analysis.matgenlab.core.Structure(lattice, {'C', 'C'}, ...
    [0 0 0.5; 1/3 2/3 0.5], labels={'C_A', 'C_B'});
writeStructure(layer, fullfile(outputDirectory, 'graphene-layer.json'));
report.layer = layerSummary(layer);
assert(layer.num_sites == 2);
assert(abs(report.layer.minimumPeriodicPairDistance - 2.46 / sqrt(3)) < 1e-10);

%% Explicit insertion: keep the original cell and translate the guest.
insertParameters = struct('otherModel', layer, ...
    'translation', [0 0 3.35], 'minimumDistance', 0.5);
inserted = kssolv.modeling.CommandExecutor.execute( ...
    layer, 'insert_structure', insertParameters);
report.inserted = layerSummary(inserted.model);
report.inserted.input = rmfield(insertParameters, 'otherModel');
assert(inserted.model.num_sites == 4);
assert(isequal(inserted.model.lattice.matrix, layer.lattice.matrix));
assert(abs(report.inserted.layerSeparation - 3.35) < 1e-10);
writeStructure(inserted.model, fullfile(outputDirectory, 'graphene-inserted.json'));

%% Candidate search and stacking: the two layers are the same material.
stackParameters = struct('otherModel', layer, 'gap', 3.35, 'vacuum', 15, ...
    'maximumStrain', 0.03, 'maximumRepeat', 2, 'maximumRotation', 0, ...
    'sortMode', 'area', 'candidateIndex', 1);
stacked = kssolv.modeling.CommandExecutor.execute( ...
    layer, 'stack_heterostructure', stackParameters);
report.stacked = layerSummary(stacked.model);
report.stacked.input = rmfield(stackParameters, 'otherModel');
report.stacked.analysis = stacked.analysis;
selected = stacked.analysis.candidates(stacked.analysis.selectedCandidate);
assert(selected.strain <= 0.03);
assert(abs(selected.rotationDegrees) < 1e-10);
assert(selected.atomCount == stacked.model.num_sites);
assert(stacked.model.num_sites == 4);
assert(abs(report.stacked.layerSeparation - 3.35) < 1e-10);
assert(abs(report.stacked.emptyNormalHeight - 15) < 1e-10);
assert(abs(report.stacked.cellNormalHeight - 18.35) < 1e-10);
layerIds = propertyNumbers(stacked.model, 'modeling_layer');
assert(isequal(layerIds, [1 1 2 2]));
writeStructure(stacked.model, fullfile(outputDirectory, 'graphene-stacked.json'));
saveReport(report, outputDirectory);
fprintf('INTERFACE PASS: %d candidates; selected %d; %d sites; gap %.8f A\n', ...
    numel(stacked.analysis.candidates), stacked.analysis.selectedCandidate, ...
    stacked.model.num_sites, report.stacked.layerSeparation);

%% Preserve water's two explicit O-H bonds using the original XYZ geometry.
waterSource = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, 'water.xyz'));
rawWater = waterSource.MatgenlabObject;
waterBonds = kssolv.modeling.chemistry.MoleculeDiagnostics.topology(rawWater);
assert(isequal(sortrows(waterBonds), [1 2 1; 1 3 1]));
properties = rawWater.properties;
properties.topology = struct('bonds', waterBonds, 'origin', 'source', 'schemaVersion', 1);
water = kssolv.analysis.matgenlab.core.Molecule(rawWater.species_and_occu, ...
    rawWater.cart_coords, charge=0, spin_multiplicity=1, properties=properties);
water.to(fullfile(outputDirectory, 'water-packing.json'), 'json');
waterImport = kssolv.services.fileparser.StructureIO(fullfile(outputDirectory, 'water-packing.json'));
assert(isequal(waterImport.MatgenlabObject.properties.topology.bonds, waterBonds));
ethanolSource = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, 'ethanol-optimized.json'));
ethanol = ethanolSource.MatgenlabObject;
components = {water, ethanol};
report.mixtureInput = struct('componentFiles', {{'water-packing.json', 'ethanol-optimized.json'}}, ...
    'counts', [10 10], 'compositionMode', 'count', 'seed', 23, 'minimumContact', 1.2, ...
    'densityAttempts', [1 0.1], 'densityUnit', 'g/cm3', ...
    'componentAtomCounts', [water.num_sites ethanol.num_sites], ...
    'componentMassAmu', [water.composition.weight ethanol.composition.weight]);
attempts = repmat(struct('density', 0, 'succeeded', false, 'errorIdentifier', '', 'message', ''), 1, 0);
packed = [];
% Try the default density once. If it fails, lower only density, retaining
% counts, minimum contact and the same fixed seed. Do not search seeds.
for density = [1 0.1]
    parameters = struct('otherComponents', {{ethanol}}, 'counts', [10 10], ...
        'compositionMode', 'count', 'totalMolecules', 20, 'density', density, ...
        'seed', 23, 'tolerance', 1.2, 'batchSize', 100, 'atomLimit', 100000);
    attempt = struct('density', density, 'succeeded', false, ...
        'errorIdentifier', '', 'message', '');
    try
        packed = kssolv.modeling.CommandExecutor.execute(water, 'pack_mixture', parameters);
        attempt.succeeded = true;
    catch exception
        attempt.errorIdentifier = exception.identifier;
        attempt.message = exception.message;
        fprintf('PACKING ATTEMPT: density %.3g failed: %s\n', density, exception.identifier);
    end
    attempts(end + 1) = attempt; %#ok<SAGROW>
    report.mixtureAttempts = attempts;
    saveReport(report, outputDirectory);
    if attempt.succeeded, break; end
end
assert(~isempty(packed), 'Neither predeclared density produced a feasible mixture.');
mixture = packed.model;
report.mixture = mixtureSummary(mixture, components);
report.mixture.analysis = packed.analysis;
assert(mixture.num_sites == 120);
assert(isequal(report.mixture.moleculeCountsByComponent, [10 10]));
assert(report.mixture.elementCounts.C == 20 && report.mixture.elementCounts.H == 80 ...
    && report.mixture.elementCounts.O == 20);
assert(abs(report.mixture.recomputedDensity - packed.analysis.targetDensity) < 1e-10);
assert(abs(report.mixture.reportedDensity - report.mixture.recomputedDensity) < 1e-7);
assert(report.mixture.minimumIntermolecularDistance >= 1.2);
assert(report.mixture.minimumAcrossBoundaryIntermolecularDistance >= 1.2);
assert(report.mixture.maxIntramolecularPairDistanceError < 1e-10);
assert(isequal(mixture.pbc, [true true true]));
writeStructure(mixture, fullfile(outputDirectory, 'water10-ethanol10-packed.json'));
report.mixture.allSavedStructuresReimported = true;
saveReport(report, outputDirectory);
fprintf('MIXTURE PASS: 10 water + 10 ethanol; %d atoms; density %.10g; contact %.8f A\n', ...
    mixture.num_sites, report.mixture.recomputedDensity, report.mixture.minimumIntermolecularDistance);
fprintf('COMPLETE: same-material interface and exact 10/10 mixture.\n');
clear diaryCleanup;

function summary = layerSummary(model)
matrix = model.lattice.matrix;
normal = cross(matrix(1, :), matrix(2, :)); normal = normal / norm(normal);
heights = model.cart_coords * normal.';
distanceMatrix = model.distance_matrix;
distanceMatrix(1:model.num_sites+1:end) = Inf;
span = max(heights) - min(heights);
summary = struct('sites', model.num_sites, 'lattice', matrix, 'pbc', model.pbc, ...
    'surfaceArea', norm(cross(matrix(1, :), matrix(2, :))), ...
    'cellNormalHeight', abs(dot(matrix(3, :), normal)), ...
    'layerSeparation', span, 'emptyNormalHeight', abs(dot(matrix(3, :), normal)) - span, ...
    'minimumPeriodicPairDistance', min(distanceMatrix, [], 'all'));
end

function values = propertyNumbers(model, name)
values = model.site_properties.(name);
if iscell(values), values = cell2mat(values); end
values = reshape(double(values), 1, []);
end

function writeStructure(model, path)
model.to(path, 'json');
restored = kssolv.services.fileparser.StructureIO(path);
assert(isequal(restored.MatgenlabObject.lattice.matrix, model.lattice.matrix));
assert(isequal(restored.MatgenlabObject.frac_coords, model.frac_coords));
assert(isequal(restored.MatgenlabObject.pbc, model.pbc));
assert(restored.MatgenlabObject.num_sites == model.num_sites);
for name = ["modeling_layer", "component_id", "molecule_id", "component_atom_index"]
    if isfield(model.site_properties, name)
        assert(isequal(propertyNumbers(restored.MatgenlabObject, name), propertyNumbers(model, name)));
    end
end
end

function summary = mixtureSummary(model, components)
coordinates = model.cart_coords;
matrix = model.lattice.matrix;
moleculeIds = propertyNumbers(model, 'molecule_id');
componentIds = propertyNumbers(model, 'component_id');
atomIndices = propertyNumbers(model, 'component_atom_index');
moleculeCounts = zeros(1, numel(components));
maxGeometryError = 0;
for molecule = unique(moleculeIds)
    sites = find(moleculeIds == molecule);
    component = unique(componentIds(sites));
    assert(isscalar(component));
    moleculeCounts(component) = moleculeCounts(component) + 1;
    [~, order] = sort(atomIndices(sites));
    sites = sites(order);
    reference = components{component}.cart_coords;
    assert(numel(sites) == size(reference, 1));
    for first = 1:numel(sites)-1
        for second = first+1:numel(sites)
            errorValue = abs(norm(coordinates(sites(second), :) - coordinates(sites(first), :)) ...
                - norm(reference(second, :) - reference(first, :)));
            maxGeometryError = max(maxGeometryError, errorValue);
        end
    end
end
minimum = Inf; acrossMinimum = Inf; minimumPair = []; acrossPair = []; acrossShift = [];
for first = 1:model.num_sites-1
    for second = first+1:model.num_sites
        if moleculeIds(first) == moleculeIds(second), continue; end
        fractional = (coordinates(second, :) - coordinates(first, :)) / matrix;
        shift = round(fractional);
        distance = norm((fractional - shift) * matrix);
        if distance < minimum, minimum = distance; minimumPair = [first second]; end
        if any(shift ~= 0) && distance < acrossMinimum
            acrossMinimum = distance; acrossPair = [first second]; acrossShift = shift;
        end
    end
end
counts = struct();
for site = 1:model.num_sites
    symbol = char(model(site).specie.symbol);
    if ~isfield(counts, symbol), counts.(symbol) = 0; end
    counts.(symbol) = counts.(symbol) + 1;
end
mass = sum(arrayfun(@(index) components{index}.composition.weight * moleculeCounts(index), ...
    1:numel(components)));
summary = struct('sites', model.num_sites, 'elementCounts', counts, ...
    'moleculeCountsByComponent', moleculeCounts, 'moleculeCount', numel(unique(moleculeIds)), ...
    'lattice', matrix, 'volume', model.volume, 'massAmu', mass, ...
    'recomputedDensity', mass * 1.66053906892 / model.volume, 'reportedDensity', model.density, ...
    'minimumIntermolecularDistance', minimum, 'minimumIntermolecularPair', minimumPair, ...
    'minimumAcrossBoundaryIntermolecularDistance', acrossMinimum, ...
    'minimumAcrossBoundaryPair', acrossPair, 'minimumAcrossBoundaryImageShift', acrossShift, ...
    'maxIntramolecularPairDistanceError', maxGeometryError, ...
    'outputHasExplicitTopology', isfield(model.properties, 'topology'));
end

function saveReport(report, directory)
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(directory, 'interface-packing-examples-results.json'));
end
