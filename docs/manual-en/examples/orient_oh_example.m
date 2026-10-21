% One additional parameter placement on saved inputs; no candidate rerun.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
hostInput = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, 'Pt111-normal-c.json'));
fragmentInput = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, 'oh-fragment.mol'));
host = hostInput.MatgenlabObject;
oh = fragmentInput.MatgenlabObject;
parameters = struct('adsorbateModel', oh, 'siteType', 'ontop', 'siteIndex', 1, ...
    'height', 2, 'anchorAtom', 1, 'orientationAtom', 2, ...
    'direction', [1 1 1], 'minimumDistance', 0.5);
result = kssolv.modeling.CommandExecutor.execute(host, 'place_adsorbate', parameters);
descriptor = result.model.properties.adsorbate;
normal = cross(host.lattice.matrix(1, :), host.lattice.matrix(2, :));
normal = normal / norm(normal);
site = reshape(descriptor.siteDescriptor.coordinates, 1, 3);
relative = descriptor.coordinates - site;
heights = relative * normal.';
lateral = relative - heights * normal;
bond = descriptor.coordinates(2, :) - descriptor.coordinates(1, :);
report = struct('mode', 'MATLAB-source-nojvm', 'MATLAB', version, 'JVM', usejava('jvm'), ...
    'inputHost', 'Pt111-normal-c.json', 'inputFragment', 'oh-fragment.mol', ...
    'input', rmfield(parameters, 'adsorbateModel'), 'GUIOperated', false, ...
    'candidateSearchRerun', false, 'surfaceNormal', normal, ...
    'oxygenNormalHeight', heights(1), 'hydrogenNormalHeight', heights(2), ...
    'oxygenLateralOffset', norm(lateral(1, :)), ...
    'hydrogenLateralOffset', norm(lateral(2, :)), ...
    'OHLength', norm(bond), 'OHDirectionDotNormal', dot(bond / norm(bond), normal), ...
    'coordinates', descriptor.coordinates, 'sites', result.model.num_sites);
assert(abs(heights(1) - 2) < 1e-8);
assert(abs(heights(2) - 2.96) < 1e-8);
assert(max(vecnorm(lateral, 2, 2)) < 1e-8);
assert(abs(report.OHLength - 0.96) < 1e-12);
assert(abs(report.OHDirectionDotNormal - 1) < 1e-12);
assert(result.model.num_sites == 6);
hostDistances = host.lattice.get_all_distances(host.frac_coords, ...
    host.lattice.get_fractional_coords(descriptor.coordinates));
report.minimumHostGuestPeriodicContact = min(hostDistances, [], 'all');
assert(report.minimumHostGuestPeriodicContact >= 0.5);
output = fullfile(outputDirectory, 'Pt111-normal-c-OH-outward.json');
result.model.to(output, 'json');
restored = kssolv.services.fileparser.StructureIO(output);
assert(isequal(restored.MatgenlabObject.cart_coords, result.model.cart_coords));
assert(isequal(restored.MatgenlabObject.lattice.matrix, result.model.lattice.matrix));
assert(isequal(restored.MatgenlabObject.properties.adsorbate.coordinates, descriptor.coordinates));
report.nativeJSONGeometryReimported = true;
report.reimportedMetadataBondShape = size(restored.MatgenlabObject.properties.adsorbate.bonds);
report.reimportedMetadataBondValues = reshape(restored.MatgenlabObject.properties.adsorbate.bonds, 1, []);
assert(isequal(report.reimportedMetadataBondValues, [1 2 1]));
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(outputDirectory, 'oh-outward-placement-results.json'));
disp(report);
fprintf('COMPLETE: O 2 A and H 2.96 A outward from ontop site.\n');
