% Reproduce the four-site Cu/Ni SQS teaching example, without GUI or JVM.
% The lattice constant is an illustrative starting value, not a fit or DFT result.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'), 'Run with MATLAB -nojvm.');
assert(startsWith(string(which('kssolv.modeling.CommandExecutor')), ...
    string(repositoryDirectory)));
assert(startsWith(string(which( ...
    'kssolv.analysis.matgenlab.transformations.SQSTransformation')), ...
    string(repositoryDirectory)));
diary(fullfile(outputDirectory, 'sqs-example.log'));
cleanupDiary = onCleanup(@() diary('off'));
fprintf('SQS BEGIN: MATLAB %s; architecture %s; JVM %d\n', ...
    version, computer('arch'), usejava('jvm'));

composition = kssolv.analysis.matgenlab.core.Composition( ...
    {'Cu', 0.5; 'Ni', 0.5});
fractionalCoordinates = [0 0 0; 0 .5 .5; .5 0 .5; .5 .5 0];
input = kssolv.analysis.matgenlab.core.Structure( ...
    eye(3) * 3.61, repmat({composition}, 1, 4), fractionalCoordinates);
input.properties.manual_example = struct( ...
    'name', 'Four-site equiatomic Cu/Ni SQS', ...
    'lattice_constant_note', '3.61 angstrom is an illustrative starting value');
inputSummary = summarize(input);
assert(input.num_sites == 4 && ~input.is_ordered);
assert(abs(inputSummary.composition.Cu - 2) < 1e-12);
assert(abs(inputSummary.composition.Ni - 2) < 1e-12);
assert(all(inputSummary.speciesPerSite == 2));
assert(max(abs(inputSummary.occupancies - .5), [], 'all') < 1e-12);
inputPersistence = writeAndCheck(input, 'sqs-cu-ni-input', outputDirectory);

% Re-import the distributed input before invoking the same production command
% used by the graphical modeling menu.
inputReader = kssolv.services.fileparser.StructureIO( ...
    fullfile(outputDirectory, 'sqs-cu-ni-input.json'));
parameters = struct('scaling', 1, 'searchTime', 1);
started = tic;
result = kssolv.modeling.CommandExecutor.execute( ...
    inputReader.MatgenlabObject, 'generate_sqs_model', parameters);
elapsedSeconds = toc(started);
output = result.model;
outputSummary = summarize(output);
assert(result.changed && output.num_sites == 4 && output.is_ordered);
assert(outputSummary.composition.Cu == 2 && outputSummary.composition.Ni == 2);
assert(all(outputSummary.speciesPerSite == 1));
assert(all(outputSummary.occupancies == 1));
assert(abs(outputSummary.minimumPeriodicDistance - 3.61 / sqrt(2)) < 1e-10);
assert(max(abs(output.lattice.matrix - input.lattice.matrix), [], 'all') < 1e-12);
assert(string(output.properties.sqs.search_mode) == 'exact-enumeration');
assert(output.properties.sqs.configuration_count == 6);
assert(abs(output.properties.sqs.objective_function - 1/6) < 1e-12);
outputPersistence = writeAndCheck(output, 'sqs-cu-ni-ordered', outputDirectory);

report = struct('MATLAB', version, 'architecture', computer('arch'), ...
    'mode', 'MATLAB-source-nojvm', 'JVM', usejava('jvm'), ...
    'GUIOperated', false, 'DFTCalculation', false, ...
    'command', 'generate_sqs_model', 'parameters', parameters, ...
    'coordinateUnit', 'angstrom', 'input', inputSummary, ...
    'output', outputSummary, 'sqs', output.properties.sqs, ...
    'elapsedSeconds', elapsedSeconds, ...
    'inputPersistence', inputPersistence, ...
    'outputPersistence', outputPersistence, ...
    'productionResultMessage', result.message, 'passed', true);
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(outputDirectory, 'sqs-example-results.json'));
fprintf('SQS PASS: %d sites, Cu %.0f Ni %.0f; objective %.15g; mode %s\n', ...
    output.num_sites, outputSummary.composition.Cu, outputSummary.composition.Ni, ...
    output.properties.sqs.objective_function, output.properties.sqs.search_mode);
fprintf('SQS PASS: minimum periodic distance %.12f angstrom; elapsed %.6f s\n', ...
    outputSummary.minimumPeriodicDistance, elapsedSeconds);
fprintf('SQS COMPLETE: JSON/CIF input and output re-import checks passed.\n');
clear cleanupDiary;

function summary = summarize(model)
counts = struct('Cu', 0, 'Ni', 0);
speciesPerSite = zeros(1, model.num_sites);
occupancies = zeros(0, 1);
labels = strings(1, model.num_sites);
for i = 1:model.num_sites
    site = model(i);
    siteComposition = site.species;
    [species, amounts] = siteComposition.items();
    speciesPerSite(i) = numel(species);
    for j = 1:numel(species)
        key = char(string(species{j}));
        counts.(key) = counts.(key) + amounts(j);
    end
    occupancies = [occupancies; amounts(:)]; %#ok<AGROW>
    labels(i) = string(model(i).species_string);
end
distances = zeros(0,1);
for i = 1:model.num_sites - 1
    for j = i+1:model.num_sites
        distances(end+1,1) = model.get_distance(i,j); %#ok<AGROW>
    end
end
summary = struct('sites', model.num_sites, 'isOrdered', model.is_ordered, ...
    'composition', counts, 'speciesPerSite', speciesPerSite, ...
    'occupancies', occupancies, 'siteSpecies', labels, ...
    'fractionalCoordinates', model.frac_coords, 'lattice', model.lattice.matrix, ...
    'volume', model.volume, 'pbc', model.pbc, ...
    'minimumPeriodicDistance', min(distances), 'pairDistances', distances);
end

function status = writeAndCheck(model, stem, directory)
model.to(fullfile(directory, stem + ".json"), 'json');
% Reconstruct the interchange copy with default labels: a mixed site produces
% two CIF rows, so a single custom label reused for both species is unsuitable.
siteCompositions = cell(1, model.num_sites);
for i = 1:model.num_sites
    site = model(i);
    siteCompositions{i} = site.species;
end
cifCopy = kssolv.analysis.matgenlab.core.Structure( ...
    model.lattice, siteCompositions, model.frac_coords);
cifCopy.to(fullfile(directory, stem + ".cif"), 'cif');
formats = {'json', 'cif'};
reference = summarize(model);
status = struct();
for k = 1:numel(formats)
    format = formats{k};
    reader = kssolv.services.fileparser.StructureIO( ...
        fullfile(directory, stem + "." + format));
    imported = reader.MatgenlabObject;
    observed = summarize(imported);
    assert(observed.sites == reference.sites);
    assert(observed.isOrdered == reference.isOrdered);
    assert(abs(observed.composition.Cu - reference.composition.Cu) < 1e-10);
    assert(abs(observed.composition.Ni - reference.composition.Ni) < 1e-10);
    assert(isequal(observed.speciesPerSite, reference.speciesPerSite));
    assert(max(abs(observed.occupancies-reference.occupancies)) < 1e-10);
    assert(max(abs(imported.lattice.matrix-model.lattice.matrix), [], 'all') < 1e-7);
    assert(max(abs(sort(observed.pairDistances)-sort(reference.pairDistances))) < 1e-7);
    metadataPreserved = isfield(imported.properties, 'sqs');
    if strcmp(format, 'json') && isfield(model.properties, 'sqs')
        assert(isequal(imported.properties.sqs, model.properties.sqs));
    end
    status.(format) = struct('imported', true, 'sites', imported.num_sites, ...
        'compositionAndOccupancyPreserved', true, ...
        'maximumPairDistanceError', max(abs( ...
        sort(observed.pairDistances)-sort(reference.pairDistances))), ...
        'sqsMetadataPreserved', metadataPreserved);
end
end
