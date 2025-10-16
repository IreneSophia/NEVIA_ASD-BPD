%% SCRIPT TO CONSTRUCT NM INPUTDATA IN .MAT FORMAT

clearvars

%% Data input
name = [pwd filesep 'SVM_classifier' filesep 'BOKI_NM_inputdata.csv'];
alldata = readtable(name, 'PreserveVariableNames',true);

ID = table2cell(alldata(:,"ID"));
label = table2array(alldata(:,"label"));

% body movement synchrony
f1 = table2array(alldata(:,contains(alldata.Properties.VariableNames,'bodysync')));
n1 = alldata(:,contains(alldata.Properties.VariableNames,'bodysync')).Properties.VariableNames;

% cross sync
f2 = table2array(alldata(:,contains(alldata.Properties.VariableNames,["_ROF","_LOF"])));
n2 = alldata(:,contains(alldata.Properties.VariableNames,["_ROF","_LOF"])).Properties.VariableNames;

% cross turns
f3 = table2array(alldata(:,contains(alldata.Properties.VariableNames,["self_","other_"])));
n3 = alldata(:,contains(alldata.Properties.VariableNames,["self_","other_"])).Properties.VariableNames;

% Facial expression synchrony
idx = contains(alldata.Properties.VariableNames,'_AU') & ...
    ~contains(alldata.Properties.VariableNames,'self') & ...
    ~contains(alldata.Properties.VariableNames,'other');
f4 = table2array(alldata(:,idx));
n4 = alldata(:,idx).Properties.VariableNames;

% head movement synchrony
f5 = table2array(alldata(:,contains(alldata.Properties.VariableNames,["headsync","Rx","Ry","Rz"])));
n5 = alldata(:,contains(alldata.Properties.VariableNames,["headsync","Rx","Ry","Rz"])).Properties.VariableNames;

% intrapersonal synchrony
f6 = table2array(alldata(:,contains(alldata.Properties.VariableNames,'intra')));
n6 = alldata(:,contains(alldata.Properties.VariableNames,'intra')).Properties.VariableNames;

% total movement and facial expressiveness
f7 = table2array(alldata(:,contains(alldata.Properties.VariableNames,["movement","intensity"])));
n7 = alldata(:,contains(alldata.Properties.VariableNames,["movement","intensity"])).Properties.VariableNames;

% speech
f8 = table2array(alldata(:,contains(alldata.Properties.VariableNames,"speech")));
n8 = alldata(:,contains(alldata.Properties.VariableNames,"speech")).Properties.VariableNames;


%% save NM structure
save(strrep(name, 'csv', 'mat'));


