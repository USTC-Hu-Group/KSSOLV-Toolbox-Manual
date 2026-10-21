% Silicon teaching calculation: SCF, high-symmetry bands, total DOS.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
researchDirectory = outputDirectory;
KSSOLV.startup();
diary(fullfile(researchDirectory, 'silicon-primitive-nojvm.log'));
cleanupDiary = onCleanup(@() diary('off'));
fprintf('MATLAB %s; JVM %d; %s\n', version, usejava('jvm'), computer('arch'));
rng(7, 'twister');
pseudopotential.PpType('default');
primitiveCellAngstrom = 5.4437023729394527 / 2 * [0 1 1; 1 0 1; 1 1 0];
primitiveCell = primitiveCellAngstrom / bohr2ang;
crystal = Crystal('supercell', primitiveCell, 'atomlist', Atom({'Si', 'Si'}), ...
    'xyzlist', [0 0 0; 0.25 0.25 0.25] * primitiveCell, 'name', 'Si2 primitive');
crystal.ecut = 20;
crystal.autokpts = [2 2 2 0 0 0];
crystal.extranbnd = 4;
crystal.funct = 'PBE';
scfOptions = options.SCF();
scfOptions.enableGPU = false;
scfOptions.enableParallelPool = false;
[crystal, H, X, scfInfo] = scf(crystal, scfOptions);
primitiveGeometry = struct('supercell', crystal.supercell, 'xyzlist', crystal.xyzlist);
save(fullfile(researchDirectory, 'silicon-primitive-scf.mat'), 'crystal', 'H', 'X', 'scfInfo', 'primitiveGeometry');
context = containers.Map('KeyType', 'char', 'ValueType', 'any');
context('molecule') = crystal;
context = kssolv.services.workflow.module.preprocessing. ...
    SymmetryAnalysisTask.executeWithOptions(context, struct( ...
    'symmetryThreshold', 1e-7, 'symmetryPrecision', 1e-5, ...
    'withTimeReversal', false, 'angleTolerance', -1));
symmetry = context('symmetry');
assert(norm(symmetry.primitive_lattice - primitiveCellAngstrom, 'fro') < 1e-6, ...
    'The path primitive basis must match the calculation basis.');
bandPath = cell(0,5);
for pathIndex = 1:size(symmetry.path, 1)
    pointA = symmetry.path{pathIndex,1};
    pointB = symmetry.path{pathIndex,2};
    if ~isempty(bandPath)
        bandPath{end,4} = 2;
    end
    bandPath(end+1,:) = [num2cell(symmetry.point_coords(pointA)), ...
        {8, strrep(pointA,'GAMMA','Gamma')}];
    bandPath(end+1,:) = [num2cell(symmetry.point_coords(pointB)), ...
        {8, strrep(pointB,'GAMMA','Gamma')}];
end
nscfOptions = options.NSCF();
nscfOptions.rho0 = H.rho;
nscfOptions.enableGPU = false;
nscfOptions.enableParallelPool = false;
energyBands = eband(copy(crystal), nscfOptions, bandPath);
dosCrystal = copy(crystal);
dosEnergyBands = eband(dosCrystal, nscfOptions, [4 4 4]);
energyRange = -10:0.05:10;
dos = zeros(size(energyRange));
tetrahedra = Tetrahedra(dosCrystal.nkxyz);
for energyIndex = 1:numel(energyRange)
    dos(energyIndex) = tetrahedra.computeTDOS(dosCrystal, ...
        dosEnergyBands, energyRange(energyIndex));
end
report = struct('MATLAB', version, 'JVM', usejava('jvm'), ...
    'Atoms', 2, 'PrimitiveBasisVerified', true, ...
    'Functional', 'PBE', 'Pseudopotential', 'default', ...
    'EcutHartree', 20, 'SCFGrid', [2 2 2 0 0 0], ...
    'ExtraBands', 4, 'SCFConverged', logical(scfInfo.converge), ...
    'SCFIterations', numel(scfInfo.Etotvec), 'SCFEnergyHartree', scfInfo.Etot, ...
    'SCFFinalError', scfInfo.SCFerrvec(end), ...
    'BandSegments', size(symmetry.path,1), 'BandSegmentPoints', 8, ...
    'BandArraySize', size(energyBands), 'DOSGrid', [4 4 4], ...
    'DOSFinite', all(isfinite(dos)), 'DOSNonnegative', all(dos >= -1e-12));
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(researchDirectory, 'silicon-primitive-nojvm-results.json'));
save(fullfile(researchDirectory, 'silicon-primitive-nojvm-results.mat'), ...
    'report', 'scfInfo', 'symmetry', 'bandPath', 'energyBands', ...
    'energyRange', 'dos', 'dosEnergyBands');
writematrix([energyRange(:), dos(:)], fullfile(researchDirectory, 'silicon-primitive-dos.csv'));
disp(report);
clear cleanupDiary;
