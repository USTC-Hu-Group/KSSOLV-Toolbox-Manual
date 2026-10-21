% Small geometry-only nanostructure examples for the Chinese manual.
% Run from the manual repository with MATLAB -nojvm. No GUI, DFT, or relaxation.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
researchDirectory = outputDirectory;
KSSOLV.startup();
assert(~usejava('jvm'),'Use MATLAB -nojvm.');
assert(startsWith(string(which('kssolv.modeling.CommandExecutor')),string(repositoryDirectory)));
logPath=fullfile(researchDirectory,'nano-source-run.log');
logFile=fopen(logPath,'w');assert(logFile>=0);fclose(logFile);
diary(logPath);
diaryCleanup=onCleanup(@()diary('off'));
fprintf('NANO BEGIN: MATLAB %s; arch %s; JVM %d\n',version,computer('arch'),usejava('jvm'));
fprintf('CommandExecutor: %s\n',which('kssolv.modeling.CommandExecutor'));
report=struct('mode','MATLAB-source-nojvm','MATLAB',version,'architecture',computer('arch'), ...
    'JVM',usejava('jvm'),'GUIOperated',false,'DFTCalculation',false,'relaxation',false, ...
    'coordinateUnit','angstrom','neighborCutoffAngstrom',1.65);
layerInput=kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory,'graphene-layer.json'));
layer120=layerInput.MatgenlabObject;
assert(layer120.num_sites==2 && abs(layer120.lattice.gamma-120)<1e-8);
ribbonParameters=struct('width',3,'length',2,'edgeType','armchair','vacuum',5,'maximumAtoms',500);
tubeParameters=struct('chiralIndices',[4 0],'length',2,'vacuum',6,'maximumAtoms',500);

% Diagnose the original 120-degree basis without editing any production code.
report.original120Input=summary(layer120,1.65);
[ribbon120,report.original120Ribbon]=attempt(layer120,'cut_nanoribbon',ribbonParameters);
report.original120Ribbon.acceptedForArmchairTutorial=false;
if ~isempty(ribbon120)
    ribbon120.to(fullfile(researchDirectory,'nano-diagnostic-graphene120-ribbon.json'),'json');
end
[tube120,report.original120Tube]=attempt(layer120,'roll_nanotube',tubeParameters);
report.original120Tube.acceptedForTutorial=false;
if ~isempty(tube120)
    tube120.to(fullfile(researchDirectory,'nano-diagnostic-graphene120-tube.json'),'json');
end
saveReport(report,outputDirectory);

% Existing integer supercell API: det(U)=1 changes only the lattice basis.
U=[1 0 0;1 1 0;0 0 1];
layer60=execute(layer120,'build_supercell',struct('scalingMatrix',U));
assert(layer60.num_sites==2 && abs(layer60.lattice.gamma-60)<1e-8);
assert(abs(layer60.volume-layer120.volume)<1e-9);
assert(max(abs(sort(layer60.distance_matrix(:))-sort(layer120.distance_matrix(:))))<1e-9);
report.basisChange=struct('commandId','build_supercell','integerMatrix',U,'determinant',det(U), ...
    'inputSites',layer120.num_sites,'outputSites',layer60.num_sites, ...
    'inputGamma',layer120.lattice.gamma,'outputGamma',layer60.lattice.gamma, ...
    'volumeError',abs(layer60.volume-layer120.volume));
report.input60=summary(layer60,1.65);
report.input60.persistence=writeAndCheck(layer60,'nano-graphene-60',outputDirectory);

ribbon=execute(layer60,'cut_nanoribbon',ribbonParameters);
report.ribbon=summary(ribbon,1.65);report.ribbon.parameters=ribbonParameters;
assert(ribbon.num_sites==24 && isequal(ribbon.pbc,[false true false]));
assert(abs(ribbon.lattice.lengths(2)-2*sqrt(3)*2.46)<1e-8);
assert(all(ismember(report.ribbon.neighborCounts,[2 3])));
assert(report.ribbon.minimumPeriodicDistance>1.3);
report.ribbon.persistence=writeAndCheck(ribbon,'graphene-armchair-w3-l2',outputDirectory);
fprintf('RIBBON PASS: %d sites; axial %.12f A; span %.12f A; neighbors %s\n', ...
    ribbon.num_sites,ribbon.lattice.lengths(2),report.ribbon.spans(1),mat2str(report.ribbon.neighborCounts));
saveReport(report,outputDirectory);

tube=execute(layer60,'roll_nanotube',tubeParameters);
report.tube=summary(tube,1.65);report.tube.parameters=tubeParameters;
center=tube.lattice.lengths(1:2)/2;
radial=vecnorm(tube.cart_coords(:,1:2)-center,2,2);
report.tube.measuredRadiusRange=[min(radial) max(radial)];
report.tube.axialTranslation= tube.properties.nanotube.axial_translation;
report.tube.reportedRadius=tube.properties.nanotube.radius;
assert(tube.num_sites==32 && isequal(tube.pbc,[false false true]));
assert(abs(tube.lattice.lengths(3)-2*sqrt(3)*2.46)<1e-8);
assert(all(report.tube.neighborCounts==3));
assert(max(abs(radial-4*2.46/(2*pi)))<1e-8);
assert(report.tube.minimumPeriodicDistance>1.3);
report.tube.persistence=writeAndCheck(tube,'graphene-tube-4-0-l2',outputDirectory);
fprintf('TUBE PASS: %d sites; axial %.12f A; radius %.12f A; all coordination3\n', ...
    tube.num_sites,tube.lattice.lengths(3),mean(radial));
saveReport(report,outputDirectory);

% Three bounded examples reuse the verified Cu-fcc teaching input.
cuInput=kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory,'Cu-fcc.cif'));
cu=cuInput.MatgenlabObject;
report.copperInput=summary(cu,2.8);
report.copperInput.persistence=writeAndCheck(cu,'nano-Cu-fcc-input',outputDirectory);
wireParameters=struct('direction',[0 0 1],'radius',3,'length',2,'vacuum',4,'maximumAtoms',2000);
[wire,wireRecord]=attempt(cu,'cut_nanowire',wireParameters,2.8);
if ~isempty(wire)
    assert(isequal(wire.pbc,[false false true]));
    assert(abs(wire.lattice.lengths(3)-7.22)<1e-7);
    wireRecord.persistence=writeAndCheck(wire,'Cu-wire-001-r3-l2',outputDirectory);
    fprintf('CU WIRE PASS: %d sites; min contact %.12f A\n',wire.num_sites,wireRecord.geometry.minimumPeriodicDistance);
end
report.copperWire=wireRecord;saveReport(report,outputDirectory);
dotParameters=struct('mode','dot','radius',3,'vacuum',4,'maximumAtoms',2000);
[dot,dotRecord]=attempt(cu,'quantum_dot_void',dotParameters,2.8);
if ~isempty(dot)
    assert(isequal(dot.pbc,[false false false]));
    dotRecord.persistence=writeAndCheck(dot,'Cu-dot-r3',outputDirectory);
    fprintf('CU DOT PASS: %d sites; min contact %.12f A\n',dot.num_sites,dotRecord.geometry.minimumPeriodicDistance);
end
report.copperDot=dotRecord;saveReport(report,outputDirectory);
cuHost=execute(cu,'build_supercell',struct('scalingMatrix',[2 2 2]));
assert(cuHost.num_sites==32);
report.copperVoidHost=summary(cuHost,2.8);
report.copperVoidHost.persistence=writeAndCheck(cuHost,'Cu-void-host-2x2x2',outputDirectory);
voidParameters=struct('mode','void','radius',2.7,'vacuum',4,'maximumAtoms',2000);
[void,voidRecord]=attempt(cuHost,'quantum_dot_void',voidParameters,2.8);
if ~isempty(void)
    assert(isequal(void.pbc,cuHost.pbc));
    assert(isequal(void.lattice.matrix,cuHost.lattice.matrix));
    assert(void.num_sites<cuHost.num_sites && void.num_sites>0);
    delta=void.frac_coords-.5;delta(:,void.pbc)=delta(:,void.pbc)-round(delta(:,void.pbc));
    distances=vecnorm(delta*void.lattice.matrix,2,2);
    assert(min(distances)>=2.7-1e-7);
    voidRecord.removedSites=cuHost.num_sites-void.num_sites;
    voidRecord.minimumDistanceToVoidCenter=min(distances);
    voidRecord.persistence=writeAndCheck(void,'Cu-void-r2p7',outputDirectory);
    fprintf('CU VOID PASS: %d sites remain; %d removed; center nearest %.12f A\n', ...
        void.num_sites,voidRecord.removedSites,min(distances));
end
report.copperVoid=voidRecord;
saveReport(report,outputDirectory);
fprintf('NANO COMPLETE: source geometry and JSON/CIF read checks.\n');
clear diaryCleanup

function model=execute(input,id,p)
r=kssolv.modeling.CommandExecutor.execute(input,id,p);model=r.model;
end
function [model,record]=attempt(input,id,p,cutoff)
if nargin<4,cutoff=1.65;end
model=[];record=struct('commandId',id,'parameters',p,'success',false);
try
    model=execute(input,id,p);record.success=true;record.geometry=summary(model,cutoff);
    record.errorIdentifier='';record.errorMessage='';
catch e
    record.errorIdentifier=e.identifier;record.errorMessage=e.message;
    fprintf('RECORDED FAILURE %s: %s -- %s\n',id,e.identifier,e.message);
end
end
function r=summary(model,cutoff)
A=model.lattice.matrix;pos=model.cart_coords;N=model.num_sites;
shifts=zeros(1,3);
for axis=1:3
    if model.pbc(axis)
        prev=shifts;shifts=zeros(0,3);
        for offset=-1:1,shifts=[shifts;prev+offset*A(axis,:)];end %#ok<AGROW>
    end
end
nearest=Inf(1,N);counts=zeros(1,N);minimum=Inf;zeroCounts=zeros(1,N);
for i=1:N
    v=reshape(permute(reshape(pos,1,N,3)+reshape(shifts,[],1,3)-reshape(pos(i,:),1,1,3),[2 1 3]),[],3);
    d=vecnorm(v,2,2);zeroCounts(i)=sum(d<=1e-7);d=d(d>1e-7);
    if ~isempty(d),nearest(i)=min(d);counts(i)=sum(d<cutoff);minimum=min(minimum,min(d));end
end
composition=struct();
for i=1:N
    symbol=char(model(i).specie.symbol);
    if ~isfield(composition,symbol),composition.(symbol)=0;end
    composition.(symbol)=composition.(symbol)+1;
end
assert(all(zeroCounts==1),'Coincident sites detected beyond the self term.');
r=struct('sites',N,'composition',composition,'pbc',model.pbc,'lattice',A, ...
    'lengths',model.lattice.lengths,'angles',model.lattice.angles,'volume',model.volume, ...
    'spans',max(pos,[],1)-min(pos,[],1),'minimumCoordinates',min(pos,[],1), ...
    'maximumCoordinates',max(pos,[],1),'minimumPeriodicDistance',minimum, ...
    'nearestNeighborDistances',nearest,'neighborCutoffAngstrom',cutoff,'neighborCounts',counts, ...
    'coincidentMatchesIncludingSelf',zeroCounts, ...
    'properties',model.properties);
end
function s=writeAndCheck(model,stem,directory)
model.to(fullfile(directory,stem+".json"),'json');
cifCopy=model.relabel_sites();cifCopy.to(fullfile(directory,stem+".cif"),'cif');
j=kssolv.services.fileparser.StructureIO(fullfile(directory,stem+".json"));
c=kssolv.services.fileparser.StructureIO(fullfile(directory,stem+".cif"));jm=j.MatgenlabObject;cm=c.MatgenlabObject;
assert(jm.num_sites==model.num_sites && cm.num_sites==model.num_sites);
assert(isequal(jm.pbc,model.pbc));
assert(strcmp(jsonencode(jm.properties),jsonencode(model.properties)));
for siteIndex=1:model.num_sites
    assert(string(jm(siteIndex).specie.symbol)==string(model(siteIndex).specie.symbol));
    assert(string(cm(siteIndex).specie.symbol)==string(model(siteIndex).specie.symbol));
end
assert(max(abs(jm.cart_coords-model.cart_coords),[],'all')<1e-9);
assert(max(abs(jm.lattice.matrix-model.lattice.matrix),[],'all')<1e-9);
assert(numel(unique(string(cm.labels)))==cm.num_sites);
err=max(abs(sort(jm.distance_matrix(:))-sort(cm.distance_matrix(:))));
assert(err<0.001);
s=struct('JSONImported',true,'JSONCoordinatesAndPBCPreserved',true, ...
    'CIFImported',true,'CIFPBC',cm.pbc,'CIFUniqueLabels',true, ...
    'CIFDistanceSpectrumMaxError',err,'CIFCheckToleranceAngstrom',0.001);
end
function saveReport(report,directory)
writelines(jsonencode(report,PrettyPrint=true),fullfile(directory,'nano-examples-results.json'));
end
