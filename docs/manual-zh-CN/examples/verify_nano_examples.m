% Read the saved nano fixtures without rerunning any construction command.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();assert(~usejava('jvm'),'Use MATLAB -nojvm.');
names=["nano-graphene-60","graphene-armchair-w3-l2","graphene-tube-4-0-l2", ...
    "nano-Cu-fcc-input","Cu-wire-001-r3-l2","Cu-dot-r3","Cu-void-host-2x2x2","Cu-void-r2p7"];
counts=[2 24 32 4 24 13 32 19];
pbc=[1 1 0;0 1 0;0 0 1;1 1 1;0 0 1;0 0 0;1 1 1;1 1 1];
checks=struct.empty;
for k=1:numel(names)
    j=kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory,names(k)+".json"));
    c=kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory,names(k)+".cif"));
    jm=j.MatgenlabObject;cm=c.MatgenlabObject;
    assert(jm.num_sites==counts(k) && cm.num_sites==counts(k));
    assert(isequal(jm.pbc,logical(pbc(k,:))));
    assert(numel(unique(string(cm.labels)))==cm.num_sites);
    for n=1:jm.num_sites
        assert(string(jm(n).specie.symbol)==string(cm(n).specie.symbol));
    end
    D=jm.distance_matrix;D(1:jm.num_sites+1:end)=Inf;
    minimum=min(D,[],'all');assert(minimum>1.3);
    error=max(abs(sort(jm.distance_matrix(:))-sort(cm.distance_matrix(:))));assert(error<.001);
    check=struct('name',names(k),'sites',jm.num_sites,'JSONPBC',jm.pbc,'CIFPBC',cm.pbc, ...
        'minimumPairDistance',minimum,'CIFDistanceSpectrumMaxError',error, ...
        'CIFCheckToleranceAngstrom',.001,'CIFUniqueLabels',true);
    if isempty(checks),checks=check;else,checks(end+1)=check;end %#ok<SAGROW>
    fprintf('NANO IMPORT PASS: %s; %d sites; minimum %.12f A; CIF spectrum error %.12g A\n', ...
        names(k),jm.num_sites,minimum,error);
end
report=struct('mode','MATLAB-source-nojvm','MATLAB',version,'JVM',usejava('jvm'), ...
    'GUIOperated',false,'constructionRerun',false,'JSONImports',8,'CIFImports',8,'checks',checks);
writelines(jsonencode(report,PrettyPrint=true),fullfile(outputDirectory,'nano-examples-verification.json'));
fprintf('ALL NANO FIXTURES REIMPORTED: eight JSON and eight CIF files.\n');
