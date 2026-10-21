% Reproduce the structural modeling examples in Chapters 7 and 8.
% Run from the manual repository with MATLAB -nojvm. No DFT calculation is performed.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'), 'Run this reference experiment with -nojvm.');
diary(fullfile(outputDirectory, 'modeling-examples.log'));
diaryCleanup = onCleanup(@() diary('off'));
fprintf('MATLAB %s; architecture %s; JVM %d\n', ...
    version, computer('arch'), usejava('jvm'));
fprintf('CommandExecutor: %s\n', which('kssolv.modeling.CommandExecutor'));
fprintf('Spglib: %s\n', which('kssolv.analysis.spglib.Spglib'));
report = struct('MATLAB', version, 'architecture', computer('arch'), ...
    'JVM', usejava('jvm'), 'mode', 'MATLAB-source-nojvm', ...
    'coordinateUnit', 'angstrom', 'angleUnit', 'degree', ...
    'DFTCalculation', false);

%% Benzene: ring, then hydrogen atoms.
ringParameters = struct('ringSize', 6, 'species', 'C', ...
    'center', [0 0 0], 'normal', [0 0 1], ...
    'bondLength', 1.4, 'aromatic', true, 'attachTo', 0);
benzeneRing = command(blankMolecule(), 'sketch_ring', ringParameters);
benzene = command(benzeneRing, 'add_hydrogens', ...
    struct('indices', 1:benzeneRing.num_sites));
report.benzene = moleculeSummary(benzene);
assert(isequal(report.benzene.elementCounts, struct('C', 6, 'H', 6)));
assert(report.benzene.bondCount == 12);
assert(report.benzene.aromaticBondCount == 6);
report.benzene.ringPlanarityDeviation = max(abs(benzeneRing.cart_coords(:, 3)));
assert(report.benzene.ringPlanarityDeviation < 1e-10);
writeMolecule(benzeneRing, 'benzene-ring.json', outputDirectory);
writeMolecule(benzene, 'benzene.json', outputDirectory);
benzeneOptimized = kssolv.modeling.CommandExecutor.execute( ...
    benzene, 'optimize_geometry', struct('maximumIterations', 200, 'forceTolerance', 0.001));
report.benzeneOptimization = benzeneOptimized.analysis;
report.benzeneOptimized = moleculeSummary(benzeneOptimized.model);
writeMolecule(benzeneOptimized.model, 'benzene-optimized.json', outputDirectory);
saveReport(report, outputDirectory);

%% Pyridine: reproduce removal of H, atom replacement, and addition of H.
pyridineRing = command(benzene, 'remove_hydrogens', ...
    struct('indices', 1:benzene.num_sites));
pyridineRing = command(pyridineRing, 'set_atom_chemistry', ...
    struct('indices', 1, 'species', 'N', 'formalCharge', 0, ...
    'hybridization', 'sp2', 'aromatic', true));
pyridine = command(pyridineRing, 'add_hydrogens', ...
    struct('indices', 1:pyridineRing.num_sites));
% The skeleton has odd electron count. After completing C5H5N, explicitly
% restore the closed-shell multiplicity before writing a reusable fixture.
report.pyridineRawSpinMultiplicity = pyridine.spin_multiplicity;
pyridine = pyridine.set_charge_and_spin(0, 1);
report.pyridine = moleculeSummary(pyridine);
assert(isequal(report.pyridine.elementCounts, struct('N', 1, 'C', 5, 'H', 5)));
assert(report.pyridine.bondCount == 11);
assert(report.pyridine.aromaticBondCount == 6);
writeMolecule(pyridine, 'pyridine.json', outputDirectory);
report.pyridine.ringPlanarityDeviation = max(abs(pyridineRing.cart_coords(:, 3)));
assert(report.pyridine.ringPlanarityDeviation < 1e-10);
pyridineOptimized = kssolv.modeling.CommandExecutor.execute( ...
    pyridine, 'optimize_geometry', struct('maximumIterations', 200, 'forceTolerance', 0.001));
report.pyridineOptimization = pyridineOptimized.analysis;
report.pyridineOptimized = moleculeSummary(pyridineOptimized.model);
writeMolecule(pyridineOptimized.model, 'pyridine-optimized.json', outputDirectory);
saveReport(report, outputDirectory);

%% Ethanol: exact coordinates, complete topology, and geometry edits.
ethanol = blankMolecule();
ethanol = command(ethanol, 'sketch_atom', struct( ...
    'species', 'C', 'coordinates', [0 0 0], 'connectTo', 0));
ethanol = command(ethanol, 'sketch_atom', struct( ...
    'species', 'C', 'coordinates', [1.52 0 0], ...
    'connectTo', 1, 'bondOrder', 1, 'useIdealBondLength', false));
ethanol = command(ethanol, 'sketch_atom', struct( ...
    'species', 'O', 'coordinates', [2.95 0 0], ...
    'connectTo', 2, 'bondOrder', 1, 'useIdealBondLength', false));
writeMolecule(ethanol, 'ethanol-backbone.json', outputDirectory);
ethanol = command(ethanol, 'add_hydrogens', ...
    struct('indices', 1:ethanol.num_sites));
report.ethanolInitial = moleculeSummary(ethanol);
assert(isequal(report.ethanolInitial.elementCounts, struct('C', 2, 'O', 1, 'H', 6)));
assert(report.ethanolInitial.bondCount == 8);
writeMolecule(ethanol, 'ethanol-initial.json', outputDirectory);
ethanol = command(ethanol, 'set_distance', struct( ...
    'indices', [1 2], 'value', 1.52, 'scope', 'subtree'));
ethanol = command(ethanol, 'set_angle', struct( ...
    'indices', [1 2 3], 'value', 109.5, 'scope', 'subtree'));
bonds = ethanol.properties.topology.bonds;
oxygenBonds = bonds(any(bonds(:, 1:2) == 3, 2), 1:2);
oxygenNeighbors = setdiff(oxygenBonds(:), 3);
hydrogenIndex = oxygenNeighbors(arrayfun( ...
    @(index) string(ethanol(index).specie.symbol) == "H", oxygenNeighbors));
assert(isscalar(hydrogenIndex));
dihedralIndices = [1 2 3 hydrogenIndex];
ethanol = command(ethanol, 'set_dihedral', struct( ...
    'indices', dihedralIndices, 'value', 60, 'scope', 'subtree'));
report.ethanolEdited = moleculeSummary(ethanol);
report.ethanolEdited.oxygenHydrogenIndex = hydrogenIndex;
report.ethanolEdited.distanceCC = measure(ethanol, [1 2]);
report.ethanolEdited.angleCCO = measure(ethanol, [1 2 3]);
report.ethanolEdited.dihedralCCOH = measure(ethanol, dihedralIndices);
assert(abs(report.ethanolEdited.distanceCC - 1.52) < 1e-10);
assert(abs(report.ethanolEdited.angleCCO - 109.5) < 1e-8);
assert(abs(report.ethanolEdited.dihedralCCOH - 60) < 1e-8);
writeMolecule(ethanol, 'ethanol-edited.json', outputDirectory);
cleanResult = kssolv.modeling.CommandExecutor.execute( ...
    ethanol, 'clean_geometry', struct('iterations', 4));
report.ethanolClean = cleanResult.analysis;
writeMolecule(cleanResult.model, 'ethanol-cleaned.json', outputDirectory);
optimizationParameters = struct('maximumIterations', 200, ...
    'forceTolerance', 0.001, 'fixedIndices', zeros(1, 0));
optimizationResult = kssolv.modeling.CommandExecutor.execute( ...
    cleanResult.model, 'optimize_geometry', optimizationParameters);
report.ethanolOptimization = optimizationResult.analysis;
report.ethanolOptimized = moleculeSummary(optimizationResult.model);
report.ethanolOptimized.distanceCC = measure(optimizationResult.model, [1 2]);
report.ethanolOptimized.angleCCO = measure(optimizationResult.model, [1 2 3]);
report.ethanolOptimized.dihedralCCOH = measure(optimizationResult.model, dihedralIndices);
assert(report.ethanolOptimized.bondCount == 8);
assert(isequal(report.ethanolOptimized.elementCounts, report.ethanolInitial.elementCounts));
writeMolecule(optimizationResult.model, 'ethanol-optimized.json', outputDirectory);
saveReport(report, outputDirectory);

%% Copper space-group construction and a symmetry-unique vacancy.
seed = kssolv.analysis.matgenlab.core.Structure( ...
    eye(3) * 5, {'Si'}, [0 0 0]);
cuResult = kssolv.modeling.CommandExecutor.execute(seed, ...
    'build_from_spacegroup', struct('spaceGroup', 'Fm-3m', ...
    'lattice', eye(3) * 3.61, 'species', 'Cu', ...
    'fractionalCoordinates', [0 0 0], 'occupancies', 1, ...
    'collisionTolerance', 0.1));
cu = cuResult.model;
report.copper = crystalSummary(cu);
report.copper.constructionAnalysis = cuResult.analysis;
assert(cu.num_sites == 4);
cu.to(fullfile(outputDirectory, 'Cu-fcc.cif'), 'cif');
defects = kssolv.modeling.CommandExecutor.execute(cu, ...
    'enumerate_point_defects', struct('defectType', 'vacancy', ...
    'indices', 1:cu.num_sites, 'symprec', 0.01, 'angleTolerance', 5));
report.copperVacancy = struct('candidateCount', numel(defects.data.variants), ...
    'degeneracies', defects.data.degeneracies, ...
    'minimumContacts', defects.data.minimumContacts, ...
    'netCharges', defects.data.netCharges, ...
    'sites', defects.data.variants{1}.num_sites);
assert(report.copperVacancy.candidateCount == 1);
assert(report.copperVacancy.degeneracies == 4);
assert(report.copperVacancy.sites == 3);
defects.data.variants{1}.to(fullfile(outputDirectory, 'Cu-vacancy.cif'), 'cif');
saveReport(report, outputDirectory);

%% Platinum (111): measure atom-plane span and the periodic empty gap.
ptResult = kssolv.modeling.CommandExecutor.execute(seed, ...
    'build_from_spacegroup', struct('spaceGroup', 'Fm-3m', ...
    'lattice', eye(3) * 3.92, 'species', 'Pt', ...
    'fractionalCoordinates', [0 0 0], 'occupancies', 1, ...
    'collisionTolerance', 0.1));
pt = ptResult.model;
report.platinumBulk = crystalSummary(pt);
pt.to(fullfile(outputDirectory, 'Pt-fcc.cif'), 'cif');
slabParameters = struct('millerIndex', [1 1 1], 'slabSize', 8, ...
    'vacuumSize', 10, 'centerSlab', true, 'primitive', true, ...
    'terminationIndex', 1);
slabResult = kssolv.modeling.CommandExecutor.execute(pt, 'build_slab', slabParameters);
slab = slabResult.model;
matrix = slab.lattice.matrix;
normal = cross(matrix(1, :), matrix(2, :));
normal = normal / norm(normal);
heights = slab.cart_coords * normal.';
normalHeight = abs(dot(matrix(3, :), normal));
report.platinumSlab = crystalSummary(slab);
report.platinumSlab.input = slabParameters;
report.platinumSlab.analysis = slabResult.analysis;
report.platinumSlab.layerCount = slab.properties.surface.layerCount;
report.platinumSlab.cellNormalHeight = normalHeight;
report.platinumSlab.atomPlaneSpan = max(heights) - min(heights);
report.platinumSlab.periodicEmptyGap = normalHeight - (max(heights) - min(heights));
report.platinumSlab.sortedNormalCoordinates = sort(heights).';
assert(report.platinumSlab.periodicEmptyGap >= 10 - 1e-8);
slab.to(fullfile(outputDirectory, 'Pt111-slab.cif'), 'cif');
fixedResult = kssolv.modeling.CommandExecutor.execute(slab, 'fix_atoms', ...
    struct('bottomLayerCount', 1));
report.platinumSlab.fixedBottomAnalysis = fixedResult.analysis;
fixedFlags = fixedResult.model.site_properties.surface_fixed;
if iscell(fixedFlags), fixedFlags = cell2mat(fixedFlags); end
report.platinumSlab.fixedBottomIndices = find(fixedFlags);
assert(numel(report.platinumSlab.fixedBottomIndices) >= 1);
saveReport(report, outputDirectory);
fprintf('COMPLETE: molecular formulas/bonds and exact edits; Cu/Pt constructions.\n');
disp(report.ethanolOptimization);
disp(report.platinumSlab);
clear diaryCleanup;

function model = blankMolecule()
properties = struct('topology', struct('bonds', zeros(0, 3), ...
    'origin', 'source', 'schemaVersion', 1));
model = kssolv.analysis.matgenlab.core.Molecule( ...
    cell(1, 0), zeros(0, 3), charge_spin_check=false, properties=properties);
end

function model = command(model, name, parameters)
result = kssolv.modeling.CommandExecutor.execute(model, name, parameters);
model = result.model;
end

function value = measure(model, indices)
result = kssolv.modeling.CommandExecutor.execute( ...
    model, 'measure_geometry', struct('indices', indices));
value = result.analysis.value;
end

function summary = moleculeSummary(model)
counts = struct();
for index = 1:model.num_sites
    symbol = char(model(index).specie.symbol);
    if ~isfield(counts, symbol), counts.(symbol) = 0; end
    counts.(symbol) = counts.(symbol) + 1;
end
bonds = model.properties.topology.bonds;
coordinates = model.cart_coords;
centered = coordinates - mean(coordinates, 1);
[~, ~, directions] = svd(centered, 0);
planarity = max(abs(centered * directions(:, end)));
diagnostics = kssolv.modeling.chemistry.MoleculeDiagnostics.inspect(model);
summary = struct('sites', model.num_sites, 'elementCounts', counts, ...
    'charge', model.charge, 'spinMultiplicity', model.spin_multiplicity, ...
    'bondCount', size(bonds, 1), 'aromaticBondCount', sum(bonds(:, 3) == 1.5), ...
    'coordinates', coordinates, 'bonds', bonds, ...
    'planarityDeviation', planarity, 'diagnostics', diagnostics);
end

function summary = crystalSummary(model)
summary = struct('sites', model.num_sites, 'formula', string(model.formula), ...
    'lattice', model.lattice.matrix, 'fractionalCoordinates', model.frac_coords);
end

function writeMolecule(model, name, directory)
path = fullfile(directory, name);
model.to(path, 'json');
restored = kssolv.analysis.matgenlab.core.Molecule.from_file(path);
assert(restored.num_sites == model.num_sites);
assert(isequal(restored.properties.topology.bonds, model.properties.topology.bonds));
assert(max(abs(restored.cart_coords - model.cart_coords), [], 'all') <= 1e-12);
parsed = kssolv.services.fileparser.StructureIO(path);
assert(parsed.MatgenlabObject.num_sites == model.num_sites);
assert(isequal(parsed.MatgenlabObject.properties.topology.bonds, model.properties.topology.bonds));
end

function saveReport(report, directory)
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(directory, 'modeling-examples-results.json'));
end
