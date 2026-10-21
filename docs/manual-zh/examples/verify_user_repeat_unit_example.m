% Independently read the teaching input and dimer, without modifying the library.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
assert(startsWith(string(which('kssolv.services.fileparser.StructureIO')),string(repositoryDirectory)));
input = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory,'user-repeat-ethane-input.json'));
output = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory,'user-repeat-CC-dimer.json'));
a = input.MatgenlabObject; b = output.MatgenlabObject;
assert(a.num_sites==8 && size(a.properties.topology.bonds,1)==7);
assert(b.num_sites==14 && size(b.properties.topology.bonds,1)==13);
species = string(cellfun(@(s)s.specie.symbol,b.sites,UniformOutput=false));
assert(sum(species=="C")==4 && sum(species=="H")==10);
bonds = b.properties.topology.bonds;
assert(max(conncomp(graph(bonds(:,1),bonds(:,2))))==1);
diagnostics = kssolv.modeling.chemistry.MoleculeDiagnostics.inspect(b);
assert(~diagnostics.hasErrors && isempty(diagnostics.collisions));
entry = kssolv.modeling.polymers.RepeatUnitLibrary.get('MANUAL_CC', ...
    storePath=fullfile(exampleDirectory,'user-repeat-unit-library.json'));
assert(isequal(entry.species,["C","C"]) && entry.head==1 && entry.tail==2);
report = struct('MATLAB',version,'JVM',usejava('jvm'),'GUIOperated',false, ...
    'sourceAtoms',a.num_sites,'dimerAtoms',b.num_sites,'dimerBonds',size(bonds,1), ...
    'carbon',4,'hydrogen',10,'singleConnectedComponent',true,'diagnostics',diagnostics, ...
    'activeUnitSpecies',entry.species,'pass',true);
writelines(jsonencode(report,PrettyPrint=true),fullfile(outputDirectory,'user-repeat-unit-verification.json'));
fprintf('READBACK PASS: input8; dimer C4H10/14 atoms/13 single bonds; one component; no diagnostic errors; JVM=%d\n',usejava('jvm'));
