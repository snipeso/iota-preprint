%%% This code is very rough, and is just what was needed to automatically
%%% merge the CSV files provided with the datasets all together.


%%% merge CSV files indicating participant basic info (age, sex, handedeness)
Source = 'E:\Raw\MetadataBasic';
Destination = 'E:\Metadata';

MetadataFiles = deblank(string(ls(Source)));
MetadataFiles(~contains(MetadataFiles, '.csv')) = [];

Metadata = table();

for IndxF = 1:numel(MetadataFiles)

    T = readtable(fullfile(Source, MetadataFiles{IndxF}));
    Metadata = [Metadata; T];
end

writetable(Metadata, fullfile(Destination, 'MetadataHBN.csv'))
save(fullfile(Destination, 'MetadataHBN.mat'), 'Metadata')


%% assign metadata extra information

Destination = 'E:\Metadata';
load(fullfile(Destination, 'MetadataHBN.mat'), 'Metadata')
T = readtable(fullfile(Destination, 'Phenotypes.csv')); % You can download this csv using the LORIS platform, and renaming it accordingly


ColumnNames = T.Properties.VariableNames;

Metadata.Participant = repmat("", size(Metadata, 1), 1);
Metadata.MissingPheno = false(size(Metadata, 1), 1);
for ParticipantIdx = 1:size(Metadata, 1)

    ID = Metadata.EID{ParticipantIdx};
    Metadata.Participant(ParticipantIdx) = string(ID);
    Pheno = T(strcmp(T.Basic_Demos_EID, ID), :);
    if isempty(Pheno)
        warning(['MissingInfo for', ID])
        Metadata.MissingPheno(ParticipantIdx) = true;
        continue
    end

    Metadata.StudySite(ParticipantIdx) = Pheno.Basic_Demos_Study_Site; % I manually selected which columns I cared to save
    Metadata.Diagnosis_Category(ParticipantIdx) = Pheno.Diagnosis_ClinicianConsensus_DX_01_Cat;
    Metadata.Diagnosis_Code(ParticipantIdx) = Pheno.Diagnosis_ClinicianConsensus_DX_01_Code;
    Metadata.Diagnosis(ParticipantIdx) = Pheno.Diagnosis_ClinicianConsensus_DX_01;
    Metadata.Diagnosis_isCurrent(ParticipantIdx) = Pheno.Diagnosis_ClinicianConsensus_DX_01_Time==1;
    Metadata.hasDiagnosis(ParticipantIdx) = Pheno.Diagnosis_ClinicianConsensus_NoDX==2;
    Metadata.Diagnosis_Confirmed(ParticipantIdx) = Pheno.Diagnosis_ClinicianConsensus_DX_01_Confirmed;
    
    Categories = Pheno{1, contains(ColumnNames, 'Cat')};
    
    Metadata.DSM_Anxiety(ParticipantIdx) = any(contains(Categories, 'Anxiety Disorders'));
    Metadata.DSM_Bipolar(ParticipantIdx) = any(contains(Categories, 'Bipolar and Related Disorders'));
    Metadata.DSM_Depression(ParticipantIdx) = any(contains(Categories, 'Depressive Disorders'));
    Metadata.DSM_Conduct(ParticipantIdx) = any(contains(Categories, 'Disruptive, Impulse Control and Conduct Disorders'));
    Metadata.DSM_Elimination(ParticipantIdx) = any(contains(Categories, 'Elimination Disorders'));
    Metadata.DSM_Feeding(ParticipantIdx) = any(contains(Categories, 'Feeding and Eating Disorders'));
    Metadata.DSM_Gender(ParticipantIdx) = any(contains(Categories, 'Gender Dysphoria'));
    Metadata.DSM_Neurocognitive(ParticipantIdx) = any(contains(Categories, 'Neurocognitive Disorders'));
    Metadata.DSM_Neurodevelopmental(ParticipantIdx) = any(contains(Categories, 'Neurodevelopmental Disorders'));
    Metadata.DSM_NoDiagnosis(ParticipantIdx) = any(strcmp(Categories, 'No Diagnosis Given'));
    Metadata.DSM_Incomplete(ParticipantIdx) = any(contains(Categories, 'Incomplete Eval'));
    Metadata.DSM_OCD(ParticipantIdx) = any(contains(Categories, 'Obsessive Compulsive and Related Disorders'));
    Metadata.DSM_Other(ParticipantIdx) = any(contains(Categories, 'Other'));
    Metadata.DSM_Schizophrenia(ParticipantIdx) = any(contains(Categories, 'Schizophrenia Spectrum and other Psychotic Disorders'));
    Metadata.DSM_Addiction(ParticipantIdx) = any(contains(Categories, 'Substance Related and Addictive Disorders'));
    Metadata.DSM_Trauma(ParticipantIdx) = any(contains(Categories, 'Trauma and Stressor Related Disorders'));
end

save(fullfile(Destination, 'MetadataHBN.mat'), 'Metadata')
