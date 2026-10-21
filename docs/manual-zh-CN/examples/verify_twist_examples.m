% Independently read the saved twist fixtures without rebuilding a bilayer.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
names = ["twist-graphene-bottom", "twist-graphene-top", ...
    "graphene-twist-21p786789", "graphene-twist-target22", ...
    "graphene-hBN-twist-21p786789"];
expectedSites = [2 2 28 28 28];
checks = repmat(struct(),1,0);
for k = 1:numel(names)
    j = kssolv.services.fileparser.StructureIO( ...
        fullfile(exampleDirectory,names(k)+".json"));
    c = kssolv.services.fileparser.StructureIO( ...
        fullfile(exampleDirectory,names(k)+".cif"));
    jm = j.MatgenlabObject; cm = c.MatgenlabObject;
    assert(jm.num_sites == expectedSites(k) && cm.num_sites == expectedSites(k));
    assert(isequal(jm.pbc,[true true false]));
    assert(numel(unique(string(cm.labels))) == cm.num_sites);
    jsonDistances = sort(jm.distance_matrix(:));
    cifDistances = sort(cm.distance_matrix(:));
    distanceError = max(abs(jsonDistances-cifDistances));
    assert(distanceError < 0.0003);
    value = struct('name',names(k),'sites',jm.num_sites, ...
        'JSONPBC',jm.pbc,'CIFPBC',cm.pbc, ...
        'CIFUniqueLabels',true,'CIFDistanceSpectrumMaxError',distanceError, ...
        'CIFDistanceCheckTolerance',0.0003, ...
        'CIFHasMoireMetadata',isfield(cm.properties,'moire'));
    if k >= 3
        assert(isfield(jm.properties,'moire'));
        assert(isfield(jm.site_properties,'modeling_layer'));
        value.JSONMoireMetadata = jm.properties.moire;
        ids = jm.site_properties.modeling_layer;
        if iscell(ids), ids=cell2mat(ids); end
        assert(sum(ids==1)==14 && sum(ids==2)==14);
    else
        value.JSONMoireMetadata = struct();
    end
    if isempty(checks)
        checks = value;
    else
        checks(end+1) = value; %#ok<SAGROW>
    end
    fprintf('TWIST IMPORT PASS: %s; %d sites; CIF distance error %.12g A\n', ...
        names(k),jm.num_sites,distanceError);
end
verification = struct('mode','MATLAB-source-nojvm','JVM',usejava('jvm'), ...
    'MATLAB',version,'GUIOperated',false,'constructionRerun',false, ...
    'JSONImports',5,'CIFImports',5,'checks',checks);
writelines(jsonencode(verification,PrettyPrint=true), ...
    fullfile(outputDirectory,'twist-examples-verification.json'));
fprintf('ALL TWIST FIXTURES REIMPORTED: five JSON and five CIF files.\n');
