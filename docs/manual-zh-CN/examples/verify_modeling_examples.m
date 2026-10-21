% Check the saved modeling fixtures without repeating their construction.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
results = jsondecode(fileread(fullfile(exampleDirectory, 'modeling-examples-results.json')));
names = ["benzene-ring", "benzene", "benzene-optimized", "pyridine", ...
    "pyridine-optimized", "ethanol-backbone", "ethanol-initial", ...
    "ethanol-edited", "ethanol-cleaned", "ethanol-optimized"];
for name = names
    file = fullfile(exampleDirectory, name + ".json");
    direct = kssolv.analysis.matgenlab.core.Molecule.from_file(file);
    imported = kssolv.services.fileparser.StructureIO(file);
    assert(isa(imported.MatgenlabObject, 'kssolv.analysis.matgenlab.core.IMolecule'));
    assert(isequal(direct.properties.topology.bonds, imported.MatgenlabObject.properties.topology.bonds));
    assert(max(abs(direct.cart_coords - imported.MatgenlabObject.cart_coords), [], 'all') < 1e-12);
    assert(mod(direct.nelectrons, 2) ~= mod(direct.spin_multiplicity, 2));
    fprintf('JSON IMPORT PASS: %s; %d atoms; %d bonds\n', ...
        name, direct.num_sites, size(direct.properties.topology.bonds, 1));
end
expectedSites = [4 3 4 4];
names = ["Cu-fcc", "Cu-vacancy", "Pt-fcc", "Pt111-slab"];
for index = 1:numel(names)
    file = fullfile(exampleDirectory, names(index) + ".cif");
    imported = kssolv.services.fileparser.StructureIO(file);
    assert(imported.MatgenlabObject.num_sites == expectedSites(index));
    fprintf('CIF IMPORT PASS: %s; %d sites\n', names(index), imported.MatgenlabObject.num_sites);
end
slab = imported.MatgenlabObject;
matrix = slab.lattice.matrix;
normal = cross(matrix(1, :), matrix(2, :));
normal = normal / norm(normal);
heights = slab.cart_coords * normal.';
restoredGap = abs(dot(matrix(3, :), normal)) - (max(heights) - min(heights));
fprintf('CIF slab gap: %.12f; source gap: %.12f\n', ...
    restoredGap, results.platinumSlab.periodicEmptyGap);
% The current CIF parser converts near-1/3 and near-2/3 values through
% string(ideal), which uses a shorter decimal representation. The observed
% normal-gap change is below 0.0002 angstrom, and is recorded explicitly.
assert(abs(restoredGap - results.platinumSlab.periodicEmptyGap) < 0.0002);
edited = kssolv.analysis.matgenlab.core.Molecule.from_file( ...
    fullfile(exampleDirectory, 'ethanol-edited.json'));
assert(abs(measure(edited, [1 2]) - 1.52) < 1e-10);
assert(abs(measure(edited, [1 2 3]) - 109.5) < 1e-8);
indices = [1 2 3 results.ethanolEdited.oxygenHydrogenIndex];
assert(abs(measure(edited, indices) - 60) < 1e-8);
for name = ["benzeneOptimization", "pyridineOptimization", "ethanolOptimization"]
    analysis = results.(name);
    assert(analysis.converged && analysis.maximumForce <= 0.001);
    assert(analysis.finalEnergy <= analysis.initialEnergy);
    assert(analysis.fallbackCount == 0);
    assert(all(diff(analysis.energyTrace) <= 1e-10));
end

% Reproduce the two persistence limitations on public teaching structures.
benzene = kssolv.analysis.matgenlab.core.Molecule.from_file( ...
    fullfile(exampleDirectory, 'benzene.json'));
molCopy = kssolv.analysis.matgenlab.core.Molecule.from_str(benzene.to('', 'mol'), 'mol');
ring = all(benzene.properties.topology.bonds(:, 1:2) <= 6, 2);
assert(all(benzene.properties.topology.bonds(ring, 3) == 1.5));
assert(all(molCopy.properties.topology.bonds(ring, 3) == 2));
raw = command(benzene, 'remove_hydrogens', struct('indices', 1:benzene.num_sites));
raw = command(raw, 'set_atom_chemistry', struct('indices', 1, 'species', 'N', ...
    'formalCharge', 0, 'hybridization', 'sp2', 'aromatic', true));
raw = command(raw, 'add_hydrogens', struct('indices', 1:raw.num_sites));
assert(raw.nelectrons == 42 && raw.spin_multiplicity == 2);
rawError = '';
try
    kssolv.analysis.matgenlab.core.Molecule.from_str(raw.to('', 'json'), 'json');
catch exception
    rawError = exception.identifier;
end
assert(~isempty(rawError));
verification = struct('mode', 'MATLAB-source-nojvm', 'JVM', usejava('jvm'), ...
    'MATLAB', version, 'spglibMex', which('kssolv.analysis.spglib.symspg'), ...
    'spglibVersion', kssolv.analysis.spglib.Spglib.getVersion('full'), ...
    'molecularJSONImports', 10, 'crystalCIFImports', 4, ...
    'geometryTargetsRecheckedAfterImport', true, 'optimizationReportsChecked', 3, ...
    'restoredPlatinumPeriodicGap', restoredGap, ...
    'platinumGapCIFRoundTripError', abs(restoredGap - results.platinumSlab.periodicEmptyGap), ...
    'platinumGapCIFRoundTripTolerance', 0.0002, ...
    'MOLAromaticOrderBefore', 1.5, 'MOLAromaticOrderAfter', 2, ...
    'rawPyridineElectrons', raw.nelectrons, ...
    'rawPyridineSpinMultiplicity', raw.spin_multiplicity, ...
    'rawPyridineJSONError', rawError, 'providedPyridineSpinMultiplicity', 1);
writelines(jsonencode(verification, PrettyPrint=true), ...
    fullfile(outputDirectory, 'modeling-examples-verification.json'));
disp(verification);
fprintf('ALL SAVED MODELING FIXTURES VERIFIED.\n');

function model = command(model, name, parameters)
model = kssolv.modeling.CommandExecutor.execute(model, name, parameters).model;
end

function value = measure(model, indices)
result = kssolv.modeling.CommandExecutor.execute( ...
    model, 'measure_geometry', struct('indices', indices));
value = result.analysis.value;
end
