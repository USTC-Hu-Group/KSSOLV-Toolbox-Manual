% Export one already saved outward structure; no placement/search rerun.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
source = kssolv.services.fileparser.StructureIO( ...
    fullfile(exampleDirectory, 'Pt111-normal-c-OH-outward.json'));
source.MatgenlabObject.to(fullfile(outputDirectory, 'Pt111-OH-outward.cif'), 'cif');
restored = kssolv.services.fileparser.StructureIO( ...
    fullfile(outputDirectory, 'Pt111-OH-outward.cif'));
model = restored.MatgenlabObject;
symbols = string(cellfun(@(site) site.specie.symbol, model.sites, 'UniformOutput', false));
oxygen = find(symbols == "O"); hydrogen = find(symbols == "H"); platinum = find(symbols == "Pt");
assert(isscalar(oxygen) && isscalar(hydrogen) && numel(platinum) == 4);
normal = cross(model.lattice.matrix(1, :), model.lattice.matrix(2, :));
normal = normal / norm(normal);
heights = model.cart_coords * normal.';
oxygenHeight = heights(oxygen) - max(heights(platinum));
hydrogenHeight = heights(hydrogen) - max(heights(platinum));
distances = model.lattice.get_all_distances(model.frac_coords, model.frac_coords);
bond = distances(oxygen, hydrogen);
minimumContact = min(distances(platinum, [oxygen hydrogen]), [], 'all');
report = struct('mode', 'MATLAB-source-nojvm', 'MATLAB', version, 'JVM', usejava('jvm'), ...
    'sourceFile', 'Pt111-normal-c-OH-outward.json', 'outputFile', 'Pt111-OH-outward.cif', ...
    'placementOrSearchRerun', false, 'GUIOperated', false, 'sites', model.num_sites, ...
    'composition', struct('Pt', numel(platinum), 'O', numel(oxygen), 'H', numel(hydrogen)), ...
    'oxygenNormalHeight', oxygenHeight, 'hydrogenNormalHeight', hydrogenHeight, ...
    'OHPeriodicDistance', bond, 'minimumPtAdsorbatePeriodicContact', minimumContact, ...
    'geometryToleranceAngstrom', 1e-5, ...
    'explicitMolecularTopologyPreserved', false, 'CIFGeometryReimported', true);
assert(model.num_sites == 6);
assert(abs(oxygenHeight - 2) < 1e-5 && abs(hydrogenHeight - 2.96) < 1e-5);
assert(abs(bond - 0.96) < 1e-5 && abs(minimumContact - 2) < 1e-5);
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(outputDirectory, 'oh-outward-cif-results.json'));
disp(report);
fprintf('COMPLETE: outward OH CIF reimported; geometry checked; no explicit molecular topology claim.\n');
