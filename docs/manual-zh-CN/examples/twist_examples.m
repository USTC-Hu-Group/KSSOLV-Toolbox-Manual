% Reproduce the small commensurate bilayers used by the Chinese manual.
% Run from the manual repository with MATLAB -nojvm. Geometry only; no DFT or GUI.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'), 'Run this example with MATLAB -nojvm.');
assert(startsWith(string(which('kssolv.modeling.builders.MoireBuilder')), ...
    string(repositoryDirectory)));
diary(fullfile(outputDirectory, 'twist-examples.log'));
cleanupDiary = onCleanup(@() diary('off'));
fprintf('TWIST BEGIN: MATLAB %s; architecture %s; JVM %d\n', ...
    version, computer('arch'), usejava('jvm'));
fprintf('MoireBuilder: %s\n', which('kssolv.modeling.builders.MoireBuilder'));
input = kssolv.services.fileparser.StructureIO( ...
    fullfile(exampleDirectory, 'graphene-layer.json'));
layer = input.MatgenlabObject;
assert(layer.num_sites == 2 && isequal(layer.pbc, [true true false]));
writeAndCheck(layer, 'twist-graphene-bottom', outputDirectory);
writeAndCheck(layer, 'twist-graphene-top', outputDirectory);
parameters = struct('angleDegrees', 21.786789, 'gap', 3.35, ...
    'vacuum', 15, 'maximumStrain', 0.03, 'maximumAtoms', 200, ...
    'maximumIndex', 6);
report = struct('mode', 'MATLAB-source-nojvm', 'MATLAB', version, ...
    'architecture', computer('arch'), 'JVM', usejava('jvm'), ...
    'GUIOperated', false, 'DFTCalculation', false, ...
    'inputSource', 'graphene-layer.json', 'input', parameters);
timer = tic;
result = build(layer, layer, parameters);
report.graphene = summarize(result);
report.graphene.elapsedSeconds = toc(timer);
assert(result.num_sites == 28);
assert(all(report.graphene.layerSiteCounts == [14 14]));
assert(abs(report.graphene.geometricTwistAngle - ...
    result.properties.moire.achieved_angle_degrees) < 1e-7);
assert(abs(report.graphene.layerGap - 3.35) < 1e-10);
assert(abs(report.graphene.cellNormalHeight - 18.35) < 1e-10);
assert(result.properties.moire.in_plane_strain < 1e-10);
report.graphene.persistence = writeAndCheck( ...
    result, 'graphene-twist-21p786789', outputDirectory);
fprintf('GRAPHENE PASS: %d sites; actual angle %.12f; geometric angle %.12f\n', ...
    result.num_sites, result.properties.moire.achieved_angle_degrees, ...
    report.graphene.geometricTwistAngle);

% A nearby requested angle selects the same small commensurate cell.
nearParameters = parameters;
nearParameters.angleDegrees = 22;
near = build(layer, layer, nearParameters);
report.nearbyTarget = summarize(near);
report.nearbyTarget.input = nearParameters;
assert(near.num_sites == 28);
assert(abs(near.properties.moire.achieved_angle_degrees - ...
    result.properties.moire.achieved_angle_degrees) < 1e-10);
report.nearbyTarget.persistence = writeAndCheck( ...
    near, 'graphene-twist-target22', outputDirectory);

% An atom cap below 28 excludes the desired cell. Success alone does not
% imply that the requested angle was reached; inspect the actual result.
limitedParameters = parameters;
limitedParameters.maximumAtoms = 24;
limited = build(layer, layer, limitedParameters);
report.restrictedAtomCap = summarize(limited);
report.restrictedAtomCap.input = limitedParameters;
assert(limited.num_sites <= 24);

% The same twist command also accepts two closely matched hexagonal layers.
bnInput = kssolv.services.fileparser.StructureIO( ...
    fullfile(exampleDirectory, 'hBN-layer.json'));
bn = bnInput.MatgenlabObject;
hetero = build(layer, bn, parameters);
report.grapheneBN = summarize(hetero);
assert(hetero.num_sites == 28);
assert(abs(hetero.properties.moire.in_plane_strain - 0.016) < 1e-10);
report.grapheneBN.persistence = writeAndCheck( ...
    hetero, 'graphene-hBN-twist-21p786789', outputDirectory);
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(outputDirectory, 'twist-examples-results.json'));
fprintf('NEAR TARGET %.9f -> %.12f degrees; atom cap24 -> %d sites, %.12f degrees\n', ...
    nearParameters.angleDegrees, near.properties.moire.achieved_angle_degrees, ...
    limited.num_sites, limited.properties.moire.achieved_angle_degrees);
fprintf('HETERO PASS: %d sites; strain %.12f\n', ...
    hetero.num_sites, hetero.properties.moire.in_plane_strain);
fprintf('TWIST COMPLETE: source geometry and JSON/CIF import checks.\n');
clear cleanupDiary;

function model = build(bottom, top, parameters)
parameters.otherModel = top;
result = kssolv.modeling.CommandExecutor.execute( ...
    bottom, 'twist_moire', parameters);
model = result.model;
end

function summary = summarize(model)
matrix = model.lattice.matrix;
normal = cross(matrix(1,:), matrix(2,:));
normal = normal / norm(normal);
coordinates = model.cart_coords;
layers = model.site_properties.modeling_layer;
if iscell(layers), layers = cell2mat(layers); end
layers = reshape(layers, [], 1);
heights = coordinates * normal.';
layerGap = mean(heights(layers == 2)) - mean(heights(layers == 1));
angles = cell(1,2); distances = zeros(1,2);
for k = 1:2
    [angles{k}, distances(k)] = neighborAngles( ...
        coordinates(layers == k,:), matrix, normal);
end
difference = mod(abs(angles{1}(:) - angles{2}(:).'), 60);
difference = min(difference, 60 - difference);
assert(max(difference, [], 'all') - min(difference, [], 'all') < 1e-7);
composition = struct();
for k = 1:model.num_sites
    symbol = char(model(k).specie.symbol);
    if ~isfield(composition, symbol), composition.(symbol) = 0; end
    composition.(symbol) = composition.(symbol) + 1;
end
summary = struct('sites', model.num_sites, 'composition', composition, ...
    'lattice', matrix, 'pbc', model.pbc, ...
    'planeLengths', vecnorm(matrix(1:2,:),2,2).', ...
    'surfaceArea', norm(cross(matrix(1,:),matrix(2,:))), ...
    'cellNormalHeight', abs(dot(matrix(3,:),normal)), ...
    'layerSiteCounts', [sum(layers == 1), sum(layers == 2)], ...
    'layerGap', layerGap, 'emptyNormalHeight', ...
    abs(dot(matrix(3,:),normal)) - (max(heights)-min(heights)), ...
    'minimumIntralayerNeighborDistances', distances, ...
    'nearestNeighborAnglesByLayer', {angles}, ...
    'geometricTwistAngle', mean(difference,'all'), ...
    'moire', model.properties.moire, ...
    'heterostructure', model.properties.heterostructure);
end

function [angles, distance] = neighborAngles(coordinates, matrix, normal)
vectors = zeros(0,3);
for i = -1:1
    for j = -1:1
        vectors = [vectors; coordinates - coordinates(1,:) + ...
            i * matrix(1,:) + j * matrix(2,:)]; %#ok<AGROW>
    end
end
lengths = vecnorm(vectors,2,2);
distance = min(lengths(lengths > 1e-6));
nearest = vectors(abs(lengths - distance) < 1e-6,:);
assert(size(nearest,1) == 3);
axis1 = matrix(1,:) / norm(matrix(1,:));
axis2 = cross(normal,axis1);
angles = atan2d(nearest * axis2.', nearest * axis1.');
end

function status = writeAndCheck(model, stem, directory)
jsonPath = fullfile(directory, stem + ".json");
cifPath = fullfile(directory, stem + ".cif");
model.to(jsonPath, 'json');
cifExport = model.relabel_sites();
assert(numel(unique(string(cifExport.labels))) == model.num_sites);
cifExport.to(cifPath, 'cif');
jsonInput = kssolv.services.fileparser.StructureIO(jsonPath);
jsonModel = jsonInput.MatgenlabObject;
assert(jsonModel.num_sites == model.num_sites);
assert(max(abs(jsonModel.cart_coords - model.cart_coords),[],'all') < 1e-10);
assert(isequal(jsonModel.pbc,model.pbc));
assert(isequal(jsonModel.lattice.matrix,model.lattice.matrix));
if isfield(model.properties,'moire')
    assert(isequal(jsonModel.properties.moire,model.properties.moire));
end
cifInput = kssolv.services.fileparser.StructureIO(cifPath);
cifModel = cifInput.MatgenlabObject;
assert(cifModel.num_sites == model.num_sites);
assert(max(abs(cifModel.lattice.lengths - model.lattice.lengths)) < 1e-5);
assert(abs(cifModel.volume - model.volume) < 1e-4);
status = struct('JSONImported',true,'JSONCoordinatesAndPBCPreserved',true, ...
    'CIFImported',true,'CIFSiteCount',cifModel.num_sites, ...
    'CIFUniqueSiteLabels',true, ...
    'CIFPBC',cifModel.pbc,'CIFVolumeError',abs(cifModel.volume-model.volume), ...
    'CIFPreservesMoireMetadata',isfield(cifModel.properties,'moire'));
end
