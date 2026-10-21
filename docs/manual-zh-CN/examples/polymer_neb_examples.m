% Structural exercises: two copolymers and a five-intermediate IDPP path.
% These are source-mode construction checks, not DFT or GUI acceptance.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
diary(fullfile(outputDirectory, 'polymer-neb-examples.log'));
diaryCleanup = onCleanup(@() diary('off'));
fprintf('MATLAB %s; JVM %d; %s\n', version, usejava('jvm'), computer('arch'));
fprintf('CommandExecutor: %s\n', which('kssolv.modeling.CommandExecutor'));
report = struct('mode', 'MATLAB-source-nojvm', 'MATLAB', version, ...
    'JVM', usejava('jvm'), 'DFTCalculation', false, 'GUIOperated', false, ...
    'coordinateUnit', 'angstrom', 'failures', struct());

%% PEO3-PPO4-PEO3: a single extended chain.
blockParameters = struct('blockKinds', 'PEO PPO PEO', 'blockLengths', [3 4 3], ...
    'superunitCount', 1, 'seed', 8, 'tacticity', 'atactic', ...
    'chainCount', 1, 'headGroup', 'none', 'tailGroup', 'none', ...
    'conformation', 'extended', 'headTailMode', 'regular', 'atomLimit', 100000);
blockResult = kssolv.modeling.CommandExecutor.execute( ...
    blankMolecule(), 'build_block_copolymer', blockParameters);
block = blockResult.model;
blockInfo = blockResult.analysis;
blockInfo.blocks = table2struct(blockInfo.blocks);
report.block = polymerSummary(block, blockInfo);
report.block.input = blockParameters;
writeMolecule(block, fullfile(outputDirectory, 'PEO3-PPO4-PEO3.json'));
saveReport(report, outputDirectory);
assert(isequal(blockResult.analysis.actualCounts, [6 4]));
assert(blockResult.analysis.repeatUnits == 10);
assert(report.block.elementCounts.C == 24 && report.block.elementCounts.H == 50 ...
    && report.block.elementCounts.O == 10);
assert(report.block.singleConnectedComponent && report.block.treeTopology);
assert(report.block.interUnitBondCount == 9 && report.block.onlyAdjacentUnitsConnected);
assert(report.block.minimumPairDistance >= 0.55);
assert(~report.block.diagnostics.hasErrors);
fprintf('BLOCK PASS: %d atoms; %d bonds; PEO6/PPO4; minimum %.8f A\n', ...
    block.num_sites, report.block.bondCount, report.block.minimumPairDistance);

%% Exact 6PE/14PP: sequence and alternating stereo metadata.
randomParameters = struct('monomerKinds', 'PE PP', 'fractions', [0.3 0.7], ...
    'repeatCount', 20, 'exactComposition', true, 'seed', 91, ...
    'tacticity', 'syndiotactic', 'reactivityRatios', [1 1], ...
    'chainCount', 1, 'headGroup', 'none', 'tailGroup', 'none', ...
    'conformation', 'extended', 'headTailMode', 'regular', 'atomLimit', 100000);
randomResult = kssolv.modeling.CommandExecutor.execute( ...
    blankMolecule(), 'build_random_copolymer', randomParameters);
random = randomResult.model;
report.random = polymerSummary(random, randomResult.analysis);
report.random.input = randomParameters;
writeMolecule(random, fullfile(outputDirectory, 'PE6-PP14-seed91.json'));
saveReport(report, outputDirectory);
assert(isequal(randomResult.analysis.actualCounts, [6 14]));
assert(report.random.elementCounts.C == 54 && report.random.elementCounts.H == 110);
assert(report.random.singleConnectedComponent && report.random.treeTopology);
assert(report.random.interUnitBondCount == 19 && report.random.onlyAdjacentUnitsConnected);
assert(report.random.minimumPairDistance >= 0.55);
assert(~report.random.diagnostics.hasErrors);
repeatIds = propertyNumbers(random, 'repeat_unit');
stereo = propertyNumbers(random, 'stereo');
report.random.stereoByUnit = arrayfun( ...
    @(unit) stereo(find(repeatIds == unit, 1)), 1:20);
assert(isequal(report.random.stereoByUnit, (-1).^(0:19)));
randomAgain = kssolv.modeling.CommandExecutor.execute( ...
    blankMolecule(), 'build_random_copolymer', randomParameters);
assert(isequal(randomResult.analysis.sequence, randomAgain.analysis.sequence));
assert(isequal(random.cart_coords, randomAgain.model.cart_coords));
assert(isequal(random.properties.topology.bonds, randomAgain.model.properties.topology.bonds));
report.random.sameSeedSequenceCoordinatesTopologyReproduced = true;
% Check whether changing tacticity changes coordinates as well as metadata.
isotacticParameters = randomParameters;
isotacticParameters.tacticity = 'isotactic';
isotactic = kssolv.modeling.CommandExecutor.execute( ...
    blankMolecule(), 'build_random_copolymer', isotacticParameters);
report.random.maxCoordinateDifferenceFromIsotactic = max(abs( ...
    random.cart_coords - isotactic.model.cart_coords), [], 'all');
report.random.stereoMetadataDifferenceFromIsotactic = any( ...
    propertyNumbers(random, 'stereo') ~= propertyNumbers(isotactic.model, 'stereo'));
saveReport(report, outputDirectory);
fprintf('RANDOM PASS: %d atoms; %d bonds; PE6/PP14; minimum %.8f A\n', ...
    random.num_sites, report.random.bondCount, report.random.minimumPairDistance);

%% A geometric exchange example, deliberately not a physical H2 reaction.
% The endpoint species/order and labels are fixed. The direct linear path
% makes the two H sites coincide at its middle image; IDPP avoids that.
pathDirectory = fullfile(outputDirectory, 'neb-exchange');
if ~isfolder(pathDirectory), mkdir(pathDirectory); end
lattice = kssolv.analysis.matgenlab.core.Lattice(eye(3) * 10, [false false false]);
initial = kssolv.analysis.matgenlab.core.Structure(lattice, {'H', 'H'}, ...
    [0.2 0.5 0.5; 0.8 0.5 0.5], labels={'H_A', 'H_B'}, ...
    site_properties=struct('teaching_site', {{1, 2}}));
ending = kssolv.analysis.matgenlab.core.Structure(lattice, {'H', 'H'}, ...
    [0.8 0.5 0.5; 0.2 0.5 0.5], labels={'H_A', 'H_B'}, ...
    site_properties=struct('teaching_site', {{1, 2}}));
initial.to(fullfile(pathDirectory, 'initial.json'), 'json');
ending.to(fullfile(pathDirectory, 'final.json'), 'json');
parameters = struct('endModel', ending, 'intermediateCount', 5, ...
    'maximumSteps', 200, 'forceTolerance', 0.1);
pathResult = kssolv.modeling.CommandExecutor.execute(initial, 'interpolate_neb', parameters);
images = pathResult.models;
pathInfo = struct('input', rmfield(parameters, 'endModel'), ...
    'diagnostics', pathResult.data, 'imageCount', numel(images), ...
    'imageLabels', pathResult.labels, 'minimumPairDistances', zeros(1, numel(images)), ...
    'linearMinimumPairDistances', zeros(1, numel(images)), ...
    'coordinates', zeros(numel(images), 2, 3), ...
    'files', strings(1, numel(images)), 'endpointMaxError', 0, ...
    'allSpeciesOrderLabelsAndSiteIdsMatch', true, 'allCellsAndPeriodicFlagsMatch', true);
assert(numel(images) == 7);
for index = 1:numel(images)
    model = images{index};
    fraction = (index - 1) / 6;
    linearCoordinates = (1 - fraction) * initial.cart_coords + fraction * ending.cart_coords;
    pathInfo.linearMinimumPairDistances(index) = norm(diff(linearCoordinates));
    pathInfo.minimumPairDistances(index) = norm(diff(model.cart_coords));
    pathInfo.coordinates(index, :, :) = model.cart_coords;
    assert(model.num_sites == 2);
    assert(all(string(cellfun(@(site) site.specie.symbol, model.sites, ...
        'UniformOutput', false)) == ["H", "H"]));
    assert(isequal(string(model.labels), string(initial.labels)));
    assert(isequal(propertyNumbers(model, 'teaching_site'), [1 2]));
    assert(isequal(model.lattice.matrix, initial.lattice.matrix));
    assert(isequal(model.pbc, initial.pbc));
    pathInfo.files(index) = "image-" + compose('%02d', index - 1) + ".json";
    model.to(fullfile(pathDirectory, pathInfo.files(index)), 'json');
    restored = kssolv.services.fileparser.StructureIO(fullfile(pathDirectory, pathInfo.files(index)));
    assert(isequal(restored.MatgenlabObject.cart_coords, model.cart_coords));
    assert(isequal(string(restored.MatgenlabObject.labels), string(model.labels)));
end
pathInfo.endpointMaxError = max([ ...
    max(abs(images{1}.cart_coords - initial.cart_coords), [], 'all'), ...
    max(abs(images{end}.cart_coords - ending.cart_coords), [], 'all')]);
report.neb = pathInfo;
saveReport(report, outputDirectory);
assert(pathInfo.endpointMaxError == 0);
assert(all(pathInfo.minimumPairDistances > 0.55));
assert(pathInfo.linearMinimumPairDistances(4) == 0);
if ~pathResult.data.converged
    report.failures.nebDefaultDidNotConverge = pathResult.data;
    saveReport(report, outputDirectory);
end
fprintf('NEB: converged %d; %d iterations; maximum force %.10g; minimum %.8f A\n', ...
    pathResult.data.converged, pathResult.data.iterations, ...
    pathResult.data.maximum_force, min(pathInfo.minimumPairDistances));
fprintf('COMPLETE: constructed polymers and saved five-intermediate IDPP path.\n');
clear diaryCleanup;

function model = blankMolecule()
model = kssolv.analysis.matgenlab.core.Molecule(cell(1, 0), zeros(0, 3), ...
    charge_spin_check=false, properties=struct('topology', ...
    struct('bonds', zeros(0, 3), 'origin', 'source', 'schemaVersion', 1)));
end

function values = propertyNumbers(model, name)
values = model.site_properties.(name);
if iscell(values), values = cell2mat(values); end
values = reshape(double(values), 1, []);
end

function summary = polymerSummary(model, info)
counts = struct();
for index = 1:model.num_sites
    symbol = char(model(index).specie.symbol);
    if ~isfield(counts, symbol), counts.(symbol) = 0; end
    counts.(symbol) = counts.(symbol) + 1;
end
bonds = model.properties.topology.bonds;
repeatIds = propertyNumbers(model, 'repeat_unit');
crossBonds = repeatIds(bonds(:, 1)) ~= repeatIds(bonds(:, 2));
interUnitPairs = [repeatIds(bonds(crossBonds, 1)).', repeatIds(bonds(crossBonds, 2)).'];
distanceMatrix = model.distance_matrix;
distanceMatrix(1:model.num_sites+1:end) = Inf;
bondMask = false(model.num_sites);
bondMask(sub2ind(size(bondMask), bonds(:, 1), bonds(:, 2))) = true;
bondMask = bondMask | bondMask.';
nonbonded = distanceMatrix;
nonbonded(bondMask) = Inf;
components = conncomp(graph(bonds(:, 1), bonds(:, 2), [], model.num_sites));
diagnostics = kssolv.modeling.chemistry.MoleculeDiagnostics.inspect(model);
summary = struct('analysis', info, 'elementCounts', counts, 'sites', model.num_sites, ...
    'bondCount', size(bonds, 1), 'minimumPairDistance', min(distanceMatrix, [], 'all'), ...
    'minimumNonbondedDistance', min(nonbonded, [], 'all'), ...
    'singleConnectedComponent', numel(unique(components)) == 1, ...
    'treeTopology', size(bonds, 1) == model.num_sites - 1, ...
    'interUnitBondCount', size(interUnitPairs, 1), ...
    'interUnitPairs', interUnitPairs, ...
    'onlyAdjacentUnitsConnected', all(abs(diff(interUnitPairs, 1, 2)) == 1), ...
    'diagnostics', diagnostics);
end

function writeMolecule(model, path)
model.to(path, 'json');
restored = kssolv.services.fileparser.StructureIO(path);
assert(isequal(restored.MatgenlabObject.cart_coords, model.cart_coords));
assert(isequal(restored.MatgenlabObject.properties.topology.bonds, model.properties.topology.bonds));
for name = ["repeat_unit", "stereo", "chain_id"]
    assert(isequal(propertyNumbers(restored.MatgenlabObject, name), propertyNumbers(model, name)));
end
end

function saveReport(report, directory)
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(directory, 'polymer-neb-examples-results.json'));
end
