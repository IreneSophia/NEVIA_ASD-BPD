load('NM_models.mat')

pvals  = [];
BAC    = [];
BACvis = [];
model  = [];
comparison  = [];

c_opt = {'ASD-COMP vs BPD-COMP', 'BPD-COMP vs COMP-COMP', ...
    'ASD-COMP vs COMP-COMP'};

for i = 1:length(NM.analysis)
    % one versus one
    for j = 1:length(c_opt)
        model  = [model; {NM.analysis{i}.id}];
        comparison  = [comparison; c_opt(j)];
        BAC    = [BAC; NM.analysis{i}.TestPerformanceBinPermAggr(j)];
        if isfield(NM.analysis{i},'visdata')
            pvals  = [pvals; mean(NM.analysis{i}.visdata{1}.PermModel_Eval_Global(j,:))];
            BACvis = [BACvis; NM.analysis{i}.visdata{1}.ObsModel_Eval_Global(j)];
        else
            pvals  = [pvals; NaN];
            BACvis = [BACvis; NaN];
        end
    end
    % multigroup
    model  = [model; {NM.analysis{i}.id}];
    comparison  = [comparison; {'MultiGroup'}];
    BAC    = [BAC; NM.analysis{i}.TestPerformanceMulti];
    if isfield(NM.analysis{i},'visdata')
        BACvis = [BACvis; NM.analysis{i}.visdata{1}.ObsModel_Eval_Global_Multi];
        pvals  = [pvals; mean(NM.analysis{i}.visdata{1}.PermModel_Eval_Global_Multi)];
    else
        pvals  = [pvals; NaN];
        BACvis = [BACvis; NaN];
    end
end

% round the values and put everything in a table
BAC    = round(BAC,1);
BACvis = round(BACvis,1);
pvals  = round(pvals, 3);
tbl = table(model, comparison, BAC, BACvis, pvals);

% save the table to csv
writetable(tbl, 'NMvalues.csv')
