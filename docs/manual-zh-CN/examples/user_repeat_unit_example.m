% Teaching example: define a two-ended ethane unit and build its dimer.
% Uses an isolated repeat-unit store in output/reference-runs; no personal library changes.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(startsWith(string(which('kssolv.modeling.CommandExecutor')), string(repositoryDirectory)));
assert(startsWith(string(which('kssolv.modeling.polymers.RepeatUnitLibrary')), string(repositoryDirectory)));
assert(~usejava('jvm'));
logPath = fullfile(outputDirectory,'user-repeat-unit-example.log');
if isfile(logPath), delete(logPath); end
diary(logPath);
diaryCleanup = onCleanup(@()diary('off'));
fprintf('BEGIN MATLAB=%s; ARCH=%s; JVM=%d\n',version,computer('arch'),usejava('jvm'));

species = ["C","C",repmat("H",1,6)];
coordinates = [0,0,0;1.52,0,0;-.3633,1.0277,0; ...
    -.3633,-.51385,.8900;-.3633,-.51385,-.8900; ...
    1.8833,-1.0277,0;1.8833,.51385,.8900;1.8833,.51385,-.8900];
bonds = [1,2,1;1,3,1;1,4,1;1,5,1;2,6,1;2,7,1;2,8,1];
properties = struct('topology',struct('bonds',bonds,'origin','source','schemaVersion',1));
source = kssolv.analysis.matgenlab.core.Molecule(cellstr(species),coordinates, ...
    charge_spin_check=false,properties=properties);
sourcePath = fullfile(outputDirectory,'user-repeat-ethane-input.json');
source.to(sourcePath,'json');
sourceRestored = kssolv.services.fileparser.StructureIO(sourcePath);
assert(isequal(sourceRestored.MatgenlabObject.cart_coords,source.cart_coords));
assert(isequal(sourceRestored.MatgenlabObject.properties.topology.bonds,bonds));
storePath = fullfile(outputDirectory,'user-repeat-unit-library.json');
name = 'MANUAL_CC';
saveParameters = struct('repeatUnitName',name,'headIndex',1,'tailIndex',2, ...
    'leavingIndices',3:8,'storePath',storePath,'overwrite',true);
saved = kssolv.modeling.CommandExecutor.execute(source,'save_user_repeat_unit',saveParameters);
assert(~saved.changed && source.num_sites==8);
entry = kssolv.modeling.polymers.RepeatUnitLibrary.get(name,storePath=storePath);
assert(numel(entry.species)==2 && entry.head==1 && entry.tail==2);
parameters = struct('repeatUnit',name,'repeatCount',2,'seed',7, ...
    'chainCount',1,'headGroup','none','tailGroup','none', ...
    'conformation','extended','headTailMode','regular','tacticity','atactic', ...
    'atomLimit',1000,'storePath',storePath);
result = kssolv.modeling.CommandExecutor.execute(source,'build_homopolymer',parameters);
output = result.model;
output.to(fullfile(outputDirectory,'user-repeat-CC-dimer.json'),'json');
restored = kssolv.services.fileparser.StructureIO(fullfile(outputDirectory,'user-repeat-CC-dimer.json'));
assert(isequal(restored.MatgenlabObject.cart_coords,output.cart_coords));
assert(isequal(restored.MatgenlabObject.properties.topology.bonds,output.properties.topology.bonds));
assert(output.num_sites==14 && size(output.properties.topology.bonds,1)==13);
actualSpecies = string(cellfun(@(s)s.specie.symbol,output.sites,UniformOutput=false));
assert(sum(actualSpecies=="C")==4 && sum(actualSpecies=="H")==10);
components = kssolv.modeling.chemistry.MoleculeDiagnostics.inspect(output);
assert(~components.hasErrors && isempty(components.collisions));
topology = output.properties.topology.bonds;
network = graph(topology(:,1),topology(:,2));
assert(max(conncomp(network))==1);
assert(isequal(size(topology),[13 3]) && all(topology(:,3)==1));
report = struct('MATLAB',version,'architecture',computer('arch'),'JVM',usejava('jvm'), ...
    'GUIOperated',false,'DFTCalculation',false,'saveParameters',saveParameters, ...
    'buildParameters',parameters,'sourceAtoms',source.num_sites, ...
    'sourceBonds',size(bonds,1),'activeUnitAtoms',numel(entry.species), ...
    'activeUnitSpecies',entry.species,'head',entry.head,'tail',entry.tail, ...
    'resultAtoms',output.num_sites,'resultBonds',size(output.properties.topology.bonds,1), ...
    'elementCounts',struct('C',sum(actualSpecies=="C"),'H',sum(actualSpecies=="H")), ...
    'coordinates',output.cart_coords,'bonds',output.properties.topology.bonds, ...
    'analysis',result.analysis,'diagnostics',components,'readbackCoordinatesAndBondsMatch',true,'singleConnectedComponent',true);
writelines(jsonencode(report,PrettyPrint=true),fullfile(outputDirectory,'user-repeat-unit-results.json'));
fprintf('PASS: source C2H6/8 atoms; active C2/2 atoms; dimer C4H10/%d atoms/%d bonds\n',output.num_sites,size(output.properties.topology.bonds,1));
fprintf('END\n');
clear diaryCleanup;
