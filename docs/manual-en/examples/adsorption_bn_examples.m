% Parameter placement/candidates for O-H on saved Pt111; graphene/h-BN match.
% Source-mode geometry only. Do not interpret scores as adsorption energies.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
diary(fullfile(outputDirectory, 'adsorption-bn-examples.log'));
diaryCleanup = onCleanup(@() diary('off'));
fprintf('MATLAB %s; JVM %d; %s\n', version, usejava('jvm'), computer('arch'));
report = struct('mode', 'MATLAB-source-nojvm', 'MATLAB', version, ...
    'JVM', usejava('jvm'), 'GUIOperated', false, 'DFTCalculation', false, ...
    'energyScoringUsed', false, 'failures', struct());

%% Read the already verified Pt111 file; do not regenerate the slab.
hostInput = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, 'Pt111-slab.cif'));
host = hostInput.MatgenlabObject;
originalHostCoordinates = host.cart_coords;
entries = kssolv.modeling.fragments.FragmentLibrary.list('', includeUser=false);
fragment = entries(strcmp(string({entries.name}), 'O-H fragment'));
assert(isscalar(fragment));
siteProperties = struct();
siteProperties.formal_charge = num2cell(fragment.formalCharges);
siteProperties.hybridization = cellstr(fragment.hybridization);
siteProperties.is_aromatic = num2cell(fragment.aromatic);
oh = kssolv.analysis.matgenlab.core.Molecule(cellstr(fragment.species), ...
    fragment.coordinates, charge=0, spin_multiplicity=2, ...
    site_properties=siteProperties, ...
    properties=struct('topology', struct('bonds', fragment.bonds, ...
    'origin', 'source', 'schemaVersion', 1)));
% A one-row bond table is flattened by the current JSON writer/reader path.
% Use native MOL for this non-aromatic, single-bond input instead.
oh.to(fullfile(outputDirectory, 'oh-fragment.mol'), 'mol');
ohImport = kssolv.services.fileparser.StructureIO(fullfile(outputDirectory, 'oh-fragment.mol'));
assert(isequal(ohImport.MatgenlabObject.properties.topology.bonds, [1 2 1]));
assert(abs(norm(diff(oh.cart_coords)) - 0.96) < 1e-12);
assert(ohImport.MatgenlabObject.spin_multiplicity == 2);
sitesResult = kssolv.modeling.CommandExecutor.execute(host, 'find_adsorption_sites', struct('distance', 2));
finder = kssolv.analysis.matgenlab.core.AdsorbateSiteFinder(host);
baseSites = finder.find_adsorption_sites(0);
normal = cross(host.lattice.matrix(1, :), host.lattice.matrix(2, :)); normal = normal / norm(normal);
cDirection = host.lattice.matrix(3, :); cDirection = cDirection / norm(cDirection);
report.adsorptionSites = struct('ontop', size(baseSites.ontop, 1), ...
    'bridge', size(baseSites.bridge, 1), 'hollow', size(baseSites.hollow, 1), ...
    'zeroOffsetCoordinates', baseSites, 'finderDistance2Coordinates', sitesResult.data, ...
    'surfaceNormal', normal, 'cDirection', cDirection, 'normalDotCDirection', dot(normal, cDirection));
placement = struct('adsorbateModel', oh, 'siteType', 'ontop', 'siteIndex', 1, ...
    'height', 2, 'anchorAtom', 1, 'orientationAtom', 0, ...
    'direction', [0 0 1], 'minimumDistance', 0.5);
placed = kssolv.modeling.CommandExecutor.execute(host, 'place_adsorbate', placement);
guestCoordinates = placed.model.properties.adsorbate.coordinates;
offset = guestCoordinates(1, :) - baseSites.ontop(1, :);
report.placed = struct('sites', placed.model.num_sites, 'composition', elementCounts(placed.model), ...
    'input', rmfield(placement, 'adsorbateModel'), 'anchorOffset', offset, ...
    'anchorOffsetAlongC', dot(offset, cDirection), ...
    'anchorOffsetAlongSurfaceNormal', dot(offset, normal), ...
    'OHLength', norm(diff(guestCoordinates)), ...
    'minimumHostGuestPeriodicContact', periodicContact(host, guestCoordinates), ...
    'metadata', placed.model.properties.adsorbate);
assert(placed.model.num_sites == 6);
assert(report.placed.composition.Pt == 4 && report.placed.composition.O == 1 && report.placed.composition.H == 1);
assert(abs(report.placed.anchorOffsetAlongC - 2) < 1e-10);
assert(abs(report.placed.anchorOffsetAlongSurfaceNormal - 2 * dot(normal, cDirection)) < 1e-10);
assert(abs(report.placed.OHLength - 0.96) < 1e-12);
assert(report.placed.minimumHostGuestPeriodicContact >= 0.5);
writeStructure(placed.model, fullfile(outputDirectory, 'Pt111-OH-c-offset.json'));
report.placed.normalHeightEqualsInputHeight = abs(report.placed.anchorOffsetAlongSurfaceNormal - 2) < 1e-8;
report.persistenceLimitation = 'Single bond [1 2 1] stored as JSON [1,2,1] decodes as 3-by-1; MOL used for OH input.';
saveReport(report, outputDirectory);

%% Existing cell-redefinition command: c' = c + 6a + 6b, determinant one.
% This preserves the periodic lattice and Cartesian atomic coordinates; it
% makes c parallel to the surface normal for an unambiguous height exercise.
basisTransform = [1 0 0; 0 1 0; 6 6 1];
assert(det(basisTransform) == 1);
normalMatrix = basisTransform * host.lattice.matrix;
normalResult = kssolv.modeling.CommandExecutor.execute(host, ...
    'redefine_lattice', struct('matrix', normalMatrix));
normalHost = normalResult.model;
normalC = normalHost.lattice.matrix(3, :); normalC = normalC / norm(normalC);
report.normalCell = struct('basisTransform', basisTransform, 'matrix', normalMatrix, ...
    'sites', normalHost.num_sites, ...
    'maxCartesianCoordinateChange', max(abs(normalHost.cart_coords - host.cart_coords), [], 'all'), ...
    'volumeChange', normalHost.volume - host.volume, ...
    'maxPeriodicDistanceChange', max(abs(normalHost.distance_matrix - host.distance_matrix), [], 'all'), ...
    'cDirectionErrorFromNormal', norm(normalC - normal));
assert(normalHost.num_sites == host.num_sites);
assert(report.normalCell.maxCartesianCoordinateChange < 1e-10);
assert(abs(report.normalCell.volumeChange) < 1e-8);
assert(report.normalCell.maxPeriodicDistanceChange < 1e-8);
assert(report.normalCell.cDirectionErrorFromNormal < 1e-8);
writeStructure(normalHost, fullfile(outputDirectory, 'Pt111-normal-c.json'));
normalPlaced = kssolv.modeling.CommandExecutor.execute(normalHost, 'place_adsorbate', placement);
normalDescriptor = normalPlaced.model.properties.adsorbate;
normalOffset = normalDescriptor.coordinates(1, :) - normalDescriptor.siteDescriptor.coordinates;
normalLateral = normalOffset - dot(normalOffset, normal) * normal;
report.normalPlaced = struct('sites', normalPlaced.model.num_sites, ...
    'composition', elementCounts(normalPlaced.model), ...
    'input', rmfield(placement, 'adsorbateModel'), ...
    'anchorHeightAlongNormal', dot(normalOffset, normal), ...
    'anchorLateralOffset', norm(normalLateral), ...
    'OHLength', norm(diff(normalDescriptor.coordinates)), ...
    'minimumHostGuestPeriodicContact', periodicContact(normalHost, normalDescriptor.coordinates));
assert(abs(report.normalPlaced.anchorHeightAlongNormal - 2) < 1e-8);
assert(report.normalPlaced.anchorLateralOffset < 1e-8);
assert(abs(report.normalPlaced.OHLength - 0.96) < 1e-12);
assert(report.normalPlaced.minimumHostGuestPeriodicContact >= 0.5);
writeStructure(normalPlaced.model, fullfile(outputDirectory, 'Pt111-normal-c-OH-ontop.json'));
saveReport(report, outputDirectory);

%% Original manual search parameters; geometric score only.
searchParameters = struct('adsorbateModel', oh, 'siteTypes', 'ontop bridge hollow', ...
    'heights', [1.8 2.1 2.4], 'rotationStep', 30, 'anchorAtom', 1, ...
    'orientationAtom', 0, 'minimumDistance', 0.6, 'maximumCandidates', 200, ...
    'seed', 0, 'scoringModel', 'kssolv-geometric-contact-v1');
searched = kssolv.modeling.CommandExecutor.execute(normalHost, 'locate_adsorbate', searchParameters);
analysis = searched.analysis;
assert(~analysis.isEnergyModel && strlength(analysis.energyUnit) == 0);
assert(analysis.candidateCount > 0 && analysis.candidateCount <= 200);
assert(issorted([analysis.candidates.score]));
maxContactError = 0;
maxBondError = 0;
maxNormalOffsetError = 0;
for candidate = reshape(analysis.candidates, 1, [])
    contact = periodicContact(normalHost, candidate.coordinates);
    maxContactError = max(maxContactError, abs(contact - candidate.minimumContact));
    maxBondError = max(maxBondError, abs(norm(diff(candidate.coordinates)) - 0.96));
    maxNormalOffsetError = max(maxNormalOffsetError, abs( ...
        dot(candidate.coordinates(1, :) - candidate.site, normal) ...
        - candidate.height));
    assert(contact >= 0.6 - 1e-10);
end
report.locator = struct('hostFile', 'Pt111-normal-c.json', ...
    'input', rmfield(searchParameters, 'adsorbateModel'), ...
    'analysis', analysis, 'maxPeriodicContactDifference', maxContactError, ...
    'maxInternalOHLengthError', maxBondError, 'maxNormalOffsetFormulaError', maxNormalOffsetError);
assert(maxContactError < 1e-9 && maxBondError < 1e-10 && maxNormalOffsetError < 1e-8);
best = kssolv.modeling.adsorption.AdsorptionLocator.applyCandidate( ...
    normalHost, oh, analysis.candidates(1), MinimumDistance=0.6);
writeStructure(best, fullfile(outputDirectory, 'Pt111-OH-candidate-1.json'));
assert(best.num_sites == 6);
assert(isequal(host.cart_coords, originalHostCoordinates));
report.locator.appliedCandidate = best.properties.adsorptionCandidate;
report.locator.inputHostCoordinatesPreserved = true;
saveReport(report, outputDirectory);
fprintf('ADSORPTION PASS: %d geometric candidates; c-offset %.8f A; normal offset %.8f A\n', ...
    analysis.candidateCount, report.placed.anchorOffsetAlongC, report.placed.anchorOffsetAlongSurfaceNormal);

%% Existing course h-BN ideal-layer parameters, not newly sourced data.
grapheneInput = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, 'graphene-layer.json'));
graphene = grapheneInput.MatgenlabObject;
hbn = kssolv.analysis.matgenlab.core.Structure( ...
    kssolv.analysis.matgenlab.core.Lattice.hexagonal(2.50, 15, pbc=[true true false]), ...
    {'B', 'N'}, [0 0 0.5; 1/3 2/3 0.5], labels={'B1', 'N1'});
writeStructure(hbn, fullfile(outputDirectory, 'hBN-layer.json'));
parameters = struct('otherModel', hbn, 'gap', 3.35, 'vacuum', 15, ...
    'maximumStrain', 0.03, 'maximumRepeat', 1, 'maximumRotation', 0, ...
    'sortMode', 'strain', 'candidateIndex', 1);
matched = kssolv.modeling.CommandExecutor.execute(graphene, 'stack_heterostructure', parameters);
candidate = matched.analysis.candidates(matched.analysis.selectedCandidate);
model = matched.model;
matrix = model.lattice.matrix;
layerIds = propertyNumbers(model, 'modeling_layer');
surfaceNormal = cross(matrix(1, :), matrix(2, :)); surfaceNormal = surfaceNormal / norm(surfaceNormal);
z = model.cart_coords * surfaceNormal.';
separation = min(z(layerIds == 2)) - max(z(layerIds == 1));
crossDistances = model.lattice.get_all_distances(model.frac_coords(layerIds == 1, :), ...
    model.frac_coords(layerIds == 2, :));
report.grapheneBN = struct('input', rmfield(parameters, 'otherModel'), ...
    'hBNLatticeInput', hbn.lattice.matrix, 'grapheneLatticeInput', graphene.lattice.matrix, ...
    'candidateAnalysis', matched.analysis, 'sites', model.num_sites, ...
    'composition', elementCounts(model), 'layerSeparation', separation, ...
    'cellNormalHeight', abs(dot(matrix(3, :), surfaceNormal)), ...
    'minimumInterlayerPeriodicContact', min(crossDistances, [], 'all'), ...
    'actualPrincipalStrain', model.properties.heterostructure.principal_strain);
assert(model.num_sites == 4);
assert(report.grapheneBN.composition.C == 2 && report.grapheneBN.composition.B == 1 && report.grapheneBN.composition.N == 1);
assert(candidate.strain <= 0.03 && abs(candidate.strain - 0.016) < 1e-10);
assert(abs(report.grapheneBN.actualPrincipalStrain - 0.016) < 1e-10);
assert(abs(separation - 3.35) < 1e-10);
assert(abs(report.grapheneBN.cellNormalHeight - 18.35) < 1e-10);
assert(report.grapheneBN.minimumInterlayerPeriodicContact >= 3.35 - 1e-10);
writeStructure(model, fullfile(outputDirectory, 'graphene-hBN-stacked.json'));
saveReport(report, outputDirectory);
fprintf('GRAPHENE/BN PASS: %d candidates; strain %.8f; %d sites; separation %.8f A\n', ...
    numel(matched.analysis.candidates), candidate.strain, model.num_sites, separation);
fprintf('COMPLETE: O-H parameter placement/candidates and a different-material layer match.\n');
clear diaryCleanup;

function minimum = periodicContact(host, coordinates)
% Independent Cartesian enumeration, sufficiently wide for this skew Pt cell.
% It covers +/-12 translations in the two short axes and +/-1 in c.
[first, second, third] = ndgrid(-12:12, -12:12, -1:1);
shifts = [first(:), second(:), third(:)] * host.lattice.matrix;
minimum = Inf;
for hostSite = 1:host.num_sites
    for guestSite = 1:size(coordinates, 1)
        vectors = coordinates(guestSite, :) - host.cart_coords(hostSite, :) + shifts;
        minimum = min(minimum, min(vecnorm(vectors, 2, 2)));
    end
end
end

function counts = elementCounts(model)
counts = struct();
for site = 1:model.num_sites
    symbol = char(model(site).specie.symbol);
    if ~isfield(counts, symbol), counts.(symbol) = 0; end
    counts.(symbol) = counts.(symbol) + 1;
end
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
assert(isequal(elementCounts(restored.MatgenlabObject), elementCounts(model)));
for name = ["adsorbate", "adsorptionCandidate", "heterostructure"]
    if isfield(model.properties, name)
        assert(isequaln(jsondecode(jsonencode(restored.MatgenlabObject.properties.(name))), ...
            jsondecode(jsonencode(model.properties.(name)))));
    end
end
end

function saveReport(report, directory)
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(directory, 'adsorption-bn-examples-results.json'));
end
