% Read-only persistence checks; do not reconstruct or rerun candidate searches.
manualPaths = manual_example_setup();
exampleDirectory = manualPaths.exampleDirectory;
outputDirectory = manualPaths.outputDirectory;
repositoryDirectory = manualPaths.toolboxRoot;
KSSOLV.startup();
assert(~usejava('jvm'));
input = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, 'oh-fragment.mol'));
oh = input.MatgenlabObject;
assert(isequal(oh.properties.topology.bonds, [1 2 1]));
assert(oh.spin_multiplicity == 2);
roundTrip = kssolv.analysis.matgenlab.core.Molecule.from_str(oh.to('', 'json'), 'json');
shapeError = '';
try
    kssolv.modeling.chemistry.MoleculeDiagnostics.topology(roundTrip);
catch exception
    shapeError = exception.identifier;
end
report = struct('mode', 'MATLAB-source-nojvm', 'JVM', usejava('jvm'), ...
    'sourceConstructionRerun', false, 'MOLBondShape', size(oh.properties.topology.bonds), ...
    'JSONBondShape', size(roundTrip.properties.topology.bonds), ...
    'JSONBondValues', reshape(roundTrip.properties.topology.bonds, 1, []), ...
    'JSONTopologyReadError', shapeError);
assert(isequal(size(roundTrip.properties.topology.bonds), [3 1]));
assert(isequal(report.JSONBondValues, [1 2 1]));
assert(strcmp(shapeError, 'KSSOLV:Modeling:MoleculeTopology'));
names = ["Pt111-OH-c-offset", "Pt111-normal-c", ...
    "Pt111-normal-c-OH-ontop", "Pt111-OH-candidate-1", "hBN-layer", "graphene-hBN-stacked"];
metadataChecks = struct();
for name = names
    parsed = kssolv.services.fileparser.StructureIO(fullfile(exampleDirectory, name + ".json"));
    model = parsed.MatgenlabObject;
    assert(all(isfinite(model.cart_coords), 'all'));
    fprintf('PERSISTENCE PASS: %s; %d sites\n', name, model.num_sites);
    for field = ["adsorbate", "adsorptionCandidate"]
        if isfield(model.properties, field)
            bonds = model.properties.(field).bonds;
            check = struct('bondArrayShape', size(bonds), ...
                'bondValues', reshape(bonds, 1, []));
            assert(isequal(check.bondValues, [1 2 1]));
            metadataChecks.(matlab.lang.makeValidName(name)) = check;
        end
    end
end
report.outputAdsorbateMetadata = metadataChecks;
report.structureFilesRead = numel(names);
report.explicitMOLInputRead = true;
writelines(jsonencode(report, PrettyPrint=true), ...
    fullfile(outputDirectory, 'adsorption-bn-persistence-results.json'));
disp(report);
fprintf('COMPLETE: saved geometries readable; single-bond JSON shape limitation reproduced.\n');
