% Silicon teaching calculation: eight-atom cell: SCF and total DOS.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
researchDirectory = outputDirectory;
KSSOLV.startup();
diary(fullfile(researchDirectory, 'silicon-nojvm.log'));
cleanupDiary = onCleanup(@() diary('off'));
fprintf('MATLAB %s; JVM %d; %s\n', version, usejava('jvm'), computer('arch'));
rng(7, 'twister');
pseudopotential.PpType('default');
crystal = example.structure.Si8();
crystal.ecut = 20;
crystal.autokpts = [2 2 2 0 0 0];
crystal.extranbnd = 4;
crystal.funct = 'PBE';
scfOptions = options.SCF();
scfOptions.enableGPU = false;
scfOptions.enableParallelPool = false;
[crystal, H, X, scfInfo] = scf(crystal, scfOptions);
save(fullfile(researchDirectory, 'silicon-scf.mat'), 'crystal', 'H', 'X', 'scfInfo');
nscfOptions = options.NSCF();
nscfOptions.rho0 = H.rho;
nscfOptions.enableGPU = false;
nscfOptions.enableParallelPool = false;
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
    'Functional', 'PBE', 'Pseudopotential', 'default', ...
    'EcutHartree', 20, 'SCFGrid', [2 2 2 0 0 0], ...
    'ExtraBands', 4, 'SCFConverged', logical(scfInfo.converge), ...
    'SCFIterations', numel(scfInfo.Etotvec), 'SCFEnergyHartree', scfInfo.Etot, ...
    'SCFFinalError', scfInfo.SCFerrvec(end), ...
    'Atoms', 8, 'DOSGrid', [4 4 4], ...
    'DOSFinite', all(isfinite(dos)), 'DOSNonnegative', all(dos >= -1e-12));
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(researchDirectory, 'silicon-nojvm-results.json'));
save(fullfile(researchDirectory, 'silicon-nojvm-results.mat'), ...
    'report', 'scfInfo', 'energyRange', 'dos', 'dosEnergyBands');
writematrix([energyRange(:), dos(:)], fullfile(researchDirectory, 'silicon-dos.csv'));
disp(report);
clear cleanupDiary;
