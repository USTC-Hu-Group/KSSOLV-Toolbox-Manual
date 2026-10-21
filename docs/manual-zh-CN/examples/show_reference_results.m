function show_reference_results(kind)
%SHOW_REFERENCE_RESULTS Redraw preserved numerical data in the active Toolbox.
% Open silicon-band-primitive.ks or silicon-tutorial.ks in the MATLAB Toolbox,
% add this examples directory to the MATLAB path, then select "bands" or "dos".
% No electronic-structure calculation is performed and no file is overwritten.
arguments
    kind (1, 1) string {mustBeMember(kind, ["bands", "dos"])}
end

project = kssolv.ui.util.DataStorage.getData('Project');
assert(~isempty(project), 'Open a reference project in the Toolbox first.');
results = project.findChildrenItem('Results');
context = [];
required = 'DOS';
if kind == "bands", required = 'bandProcessing'; end
for index = 1:numel(results.datasetsItem.children)
    candidate = results.datasetsItem.children{index}.data;
    if isa(candidate, 'containers.Map') && isKey(candidate, required)
        context = candidate;
        break
    end
end
assert(isa(context, 'containers.Map'), ...
    'The active project has no saved numerical input for this figure.');
if kind == "bands"
    task = kssolv.services.workflow.module.visualization.BandStructureTask();
    task.executeTask(context, []);
else
    kssolv.services.workflow.module.visualization.DOSTask.presentWithContext(context);
end
% Use ordinary graphics properties to make the saved data readable on screen.
% Numerical arrays, energy references and path coordinates remain unchanged.
app = kssolv.ui.util.DataStorage.getData('AppContainer');
item = results.plotsItem.children{end};
document = app.getDocument('Plot', item.name);
drawnow;
axes = findall(document.Figure, 'Type', 'Axes');
assert(~isempty(axes), 'The reference chart has no visible axes.');
for index = 1:numel(axes)
    ax = axes(index);
    axis(ax, 'normal');
    ax.FontSize = 12;
    ax.XTickLabelRotation = 0;
    ax.XLabel.FontSize = 13;
    ax.YLabel.FontSize = 13;
    ax.Title.FontSize = 13;
    if kind == "bands"
        labels = strip(string(ax.XTickLabel(:)));
        for labelIndex = 1:numel(labels)
            parts = strip(split(labels(labelIndex), '|'));
            parts(strlength(parts) == 0) = [];
            if numel(unique(parts)) == 1, labels(labelIndex) = parts(1); end
        end
        keep = [true; labels(2:end) ~= labels(1:end-1)];
        ticks = ax.XTick;
        ax.XTick = ticks(keep);
        ax.XTickLabel = replace(labels(keep), 'Gamma', '\Gamma');
    else
        set(findall(ax, 'Type', 'Line'), 'LineWidth', 1.25);
    end
end
fprintf('Reference %s redrawn from saved dataset; no calculation rerun.\n', kind);
end
