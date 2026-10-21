function paths = manual_example_setup(options)
%MANUAL_EXAMPLE_SETUP Locate an external MATLAB Toolbox and manual outputs.
% Set KSSOLV_TOOLBOX_ROOT to the full MATLAB Toolbox directory, or install
% KSSOLV_Toolbox on the MATLAB path before calling an example. The desktop
% Runtime application alone does not provide these MATLAB source APIs.
% Inputs remain in examples; generated files go to output/reference-runs.
% CreateOutputDirectory=false checks paths without writing any files.
arguments
    options.CreateOutputDirectory (1, 1) logical = true
end

exampleDirectory = fileparts(mfilename('fullpath'));
manualRoot = fileparts(fileparts(fileparts(exampleDirectory)));
toolboxRoot = strtrim(getenv('KSSOLV_TOOLBOX_ROOT'));
if isempty(toolboxRoot)
    installedEntry = which('KSSOLV_Toolbox');
    if isempty(installedEntry)
        error('KSSOLVManual:ToolboxNotFound', ...
            ['Set KSSOLV_TOOLBOX_ROOT to the MATLAB Toolbox directory, ' ...
             'or add the installed KSSOLV_Toolbox entry to the MATLAB path.']);
    end
    toolboxRoot = fileparts(installedEntry);
    resolution = 'MATLAB path';
else
    resolution = 'KSSOLV_TOOLBOX_ROOT';
end

coreDirectory = fullfile(toolboxRoot, '+kssolv', '+core', 'kssolv-3o');
if ~isfolder(coreDirectory) || ...
        ~(isfile(fullfile(toolboxRoot, 'KSSOLV_Toolbox.m')) || ...
          isfile(fullfile(toolboxRoot, 'KSSOLV_Toolbox.p')))
    error('KSSOLVManual:InvalidToolboxRoot', ...
        'The selected directory does not contain the complete MATLAB Toolbox: %s', toolboxRoot);
end
[found, attributes] = fileattrib(toolboxRoot);
if ~found
    error('KSSOLVManual:UnreadableToolboxRoot', ...
        'Cannot resolve the selected Toolbox directory: %s', toolboxRoot);
end
toolboxRoot = attributes.Name;
coreDirectory = fullfile(toolboxRoot, '+kssolv', '+core', 'kssolv-3o');
addpath(toolboxRoot, '-begin');
addpath(coreDirectory, '-begin');

outputDirectory = fullfile(manualRoot, 'output', 'reference-runs');
if options.CreateOutputDirectory && ~isfolder(outputDirectory)
    [created, message] = mkdir(outputDirectory);
    if ~created
        error('KSSOLVManual:OutputDirectory', ...
            'Cannot create the reference-run directory: %s', message);
    end
end
paths = struct('manualRoot', manualRoot, ...
    'exampleDirectory', exampleDirectory, ...
    'outputDirectory', outputDirectory, ...
    'toolboxRoot', toolboxRoot, 'coreDirectory', coreDirectory, ...
    'resolution', resolution);
end
