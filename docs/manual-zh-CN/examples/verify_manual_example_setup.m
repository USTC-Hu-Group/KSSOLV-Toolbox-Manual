function report = verify_manual_example_setup()
%VERIFY_MANUAL_EXAMPLE_SETUP Read-only bootstrap check, without calculations.
% Add this examples directory to the MATLAB path and call with MATLAB -nojvm.
% This function does not start KSSOLV, deserialize projects, create output
% directories, or write fixtures/reports. It returns paths and prints a PASS.
exampleDirectory = fileparts(mfilename('fullpath'));
manualRoot = fileparts(fileparts(fileparts(exampleDirectory)));
expectedOutput = fullfile(manualRoot, 'output', 'reference-runs');
outputExisted = isfolder(expectedOutput);
paths = manual_example_setup(CreateOutputDirectory=false);
assert(strcmp(paths.exampleDirectory, exampleDirectory));
assert(strcmp(paths.outputDirectory, expectedOutput));
assert(isfolder(expectedOutput) == outputExisted);
assert(~strcmp(paths.toolboxRoot, manualRoot));
entry = which('KSSOLV_Toolbox');
commandExecutor = which('kssolv.modeling.CommandExecutor');
assert(startsWith(entry, [paths.toolboxRoot filesep]));
assert(startsWith(commandExecutor, [paths.toolboxRoot filesep]));
assert(isfile(fullfile(exampleDirectory, 'silicon.cif')));
assert(isfile(fullfile(exampleDirectory, 'h2.cif')));
report = struct('paths', paths, 'toolboxEntry', entry, ...
    'commandExecutor', commandExecutor, 'readOnly', true, ...
    'calculationsRun', false, 'fixturesWritten', false, ...
    'outputDirectoryExisted', outputExisted);
fprintf('BOOTSTRAP PASS: %s\nToolbox: %s\nInputs: %s\nOutputs: %s\n', ...
    paths.resolution, paths.toolboxRoot, paths.exampleDirectory, paths.outputDirectory);
end
