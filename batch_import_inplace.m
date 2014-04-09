%Init
clear all;close all;

%Params
host= 'dogfish.openmicroscopy.org';  %Host address
username = 'data_repo';  %Username for Insight
password = 'drafty psalm'; %Password for Insight

pathFolder = ['/ome/data_repo/'];%#ok<*NBRAK> %Source Directory with a slash at the end
timervar={'Projectno','Imageno','Datasetno','createProject','createStore','reader','handler','Candidates1','Candidates2','CreateDataset','ImportLibrary','addObserver','setMetadataOptions','logFactory','ImportCandidates'};
folder_depth_bioformats=10;%Folder depth for bioformats to search and calculate the number of datasets
importopt=1; %Inplace import =1;
outputFolder = '/home/inplace_user/matlab_results';

%Import Packages
import loci.formats.in.DefaultMetadataOptions;
import loci.formats.in.MetadataLevel;
import loci.common.*;
import ome.formats.OMEROMetadataStoreClient;
import ome.formats.importer.*;
import ome.formats.importer.ImportConfig;
import ome.formats.importer.cli.ErrorHandler;
import ome.formats.importer.cli.LoggingImportMonitor;
import omero.model.Dataset;
import omero.model.DatasetI;
import ome.services.blitz.repo.*;
import ome.formats.importer.transfers.*;
import ome.formats.importer.transfers.SymlinkFileTransfer;
import ome.formats.importer.cli.CommandLineImporter;
import java.util.prefs.*;


%Logging (switch on)
loci.common.DebugTools.enableLogging('DEBUG');

%Configuration Object
% java.lang.System.setProperty('java.util.prefs.PreferencesFactory','java.util.prefs.MacOSXPreferencesFactory');
config = ImportConfig();

%Set Config params
config.email.set('');
config.sendFiles.set(true);
config.sendReport.set(false);
config.contOnError.set(false);
config.debug.set(false);
config.hostname.set(host);

port = javaObject('java.lang.Integer',4064);
config.port.set(port);
config.username.set(username);
config.password.set(password);
config.targetClass.set('omero.model.Dataset');

d=dir(pathFolder);
nameFolds = []; %# returns logical vector
nameFolds = [nameFolds ; {d.name}];
idx1=strmatch('.',nameFolds);
idx1=setdiff(1:length(nameFolds),idx1);
nameFolds=nameFolds(idx1);
nameFolds= setdiff(nameFolds,{'.','..','.DS_Store','._.DS_Store'});

%Load Omero
client = loadOmero(host);
session = client.createSession(username, password);
client.enableKeepAlive(60);

%Metadatastore Object
tic;store = handle(config.createStore());
store.logVersionInfo(config.getIniVersionNumber());t2=toc;

%Looped Import
wierd_folders=[];spw=[];ImportStats=[];
for i=1:length(nameFolds)

Projectname = nameFolds{i};
tic;reader = OMEROWrapper(config);t3=toc;
reader.setGroupFiles(false)
tic;handler = handle(ErrorHandler(config));t4=toc;
%     diary('log_test_images_good.txt')
paths = [pathFolder Projectname];

tic;candidates = handle(ImportCandidates(folder_depth_bioformats,reader, paths, handler));t5=toc;

%Wierd Folder Errors
if ((candidates.getContainers().size)==0)
wierd_folders=[wierd_folders ; nameFolds(i)];
continue
end

%     Check point 1 : to check if its a SWP(screen/well/plate format)
check_spw = candidates.getContainers().get(0).getIsSPW();
if check_spw.toString.matches('true')
spw=[spw ; nameFolds(i)];
continue
end

datasetno=candidates.getContainers().size;
timevec=[];errorvec={};

%Create a project
tic;project = handle(createProject(session, Projectname));t1=toc;

%calculate the files for import
getfiles=[];dataID=[];datasetvec=[];
for j=1:datasetno

getfiles=[getfiles ; cell(candidates.getContainers().get(j-1).getUsedFiles)]; %#ok<*AGROW>
getfile=char(candidates.getContainers.get(j-1).getFile);
idx1 = strfind(getfile,'/');
DatasetName = strdiff(char(getfile(1:idx1(end))),[paths '/']);%Slash (/) format for mac as of now, can be generalized later.


if isempty(DatasetName)
%             DatasetName = getfile(idx1(end)+1:length(getfile));
DatasetName = Projectname;
end

if j>1 && ~isempty(intersect(DatasetName,datasetvec(:,1)))
idx1=strmatch(DatasetName, datasetvec(:,1),'exact');
dataID= datasetvec{idx1,2};
else
tic;dataset = handle(createDataset(session, DatasetName, project.getId.getValue()));t6=toc;
dataID = javaObject('java.lang.Long',dataset.getId().getValue());
end

datasetvec=[datasetvec ; {DatasetName} {dataID}];

%Library Object
tic;
if importopt == 1
library = handle(ImportLibrary(store, reader, SymlinkFileTransfer));
else
library = handle(ImportLibrary(store, reader));
end;t7=toc;

tic;library.addObserver(LoggingImportMonitor());t8=toc;
tic;reader.setMetadataOptions(DefaultMetadataOptions(MetadataLevel.ALL));t9=toc;

tic;log = org.apache.commons.logging.LogFactory.getLog('ome.formats.importer.ImportLibrary');t10=toc;
config.targetId.set(dataID);
tic;candidates_specific= handle(ImportCandidates(folder_depth_bioformats,reader, char(candidates.getContainers.get(j-1).getFile), handler));t12=toc;

tic;success = library.importCandidates(config, candidates_specific);t11=toc;

timevec=[timevec ; i j datasetno t1 t2 t3 t4 t5 t12 t6 t7 t8 t9 t10 t11];

end
reader.close();
ImportStats=[ImportStats ; timevec];


end
store.logout();store.closeServices();

time1=clock;
DatasetName=[date '_' num2str(time1(4)) '_' num2str(time1(5)) '_ImportStats.mat'];
save([outputFolder '/' DatasetName],'ImportStats','nameFolds','spw','wierd_folders','timervar');

%Check a project named Matlab_Result
projects = getProjects(session);
for j=1:numel(projects)
pjname=char(projects(j).getName.getValue());
if ~isempty(strmatch(pjname,'Matlab_Result','exact'))
project=projects(j);
break
end
end

if j==numel(projects)
project = handle(createProject(session, 'Import_Statistics'));
end

%Create a dataset and annotate the matlab mat file to the dataset (The
                                                                   %dataset name is the current time).
dataset = handle(createDataset(session, DatasetName, project.getId.getValue()));
dataID = dataset.getId().getValue();
fileAnnotation = writeFileAnnotation(session, [outputFolder '/' DatasetName]);
link = linkAnnotation(session, fileAnnotation, 'dataset',dataID);

delete([outputFolder '/' DatasetName]);
%Logout and close session
store.logout;
client.closeSession();
unloadOmero;
pause(10);

%Load Omero and upload results
client = loadOmero(host);
session = client.createSession(username, password);
client.enableKeepAlive(60);
reader = OMEROWrapper(config);
store = handle(config.createStore());
store.logVersionInfo(config.getIniVersionNumber());
handler = handle(ErrorHandler(config));
library = handle(ImportLibrary(store, reader));

%Plot results and attach to the dataset
pid=unique(ImportStats(:,1));
for i=1:length(pid)

idx1=find(ImportStats(:,1)==pid(i));
plotvec=ImportStats(idx1,:);totval=(plotvec(:,4:end));totval=sum(totval(:));
bar(plotvec(:,4:end));xlabel('Individual Objects');ylabel('Time(secs)');title(['Total Time Taken : ' num2str(totval) ' Seconds'])

saveas(gca,[outputFolder '/' nameFolds{pid(i)} '.jpeg']) ;
close;

dataID=javaObject('java.lang.Long',dataset.getId().getValue());
config.targetId.set(dataID);
candidates_specific= (ImportCandidates(folder_depth_bioformats,reader, [outputFolder '/' nameFolds{pid(i)} '.jpeg'], handler));
success = library.importCandidates(config, candidates_specific);
delete([outputFolder '/' nameFolds{pid(i)} '.jpeg']);
end
store.logout();store.closeServices();reader.close();
%Logout and close session
store.logout;
client.closeSession();
clear all;
unloadOmero;


