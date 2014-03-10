%Init
clear all;close all;

%Params
host= 'localhost';  %Host address
username = 'test_file_handling';  %Username for Insight
password = 'test12'; %Password for Insight
%Choose a dataset name, will be assigned to your imported dataset under the root user.
ImageFormat = '.tiff'; %Image format within the source directory
pathFolder = ['/Users/bramalingam/Downloads/data_repo_good/'];%Source Directory
timervar={'Projectno','Datasetno','createProject','createStore','reader','handler','Candidates1','Candidates2','CreateDataset','ImportLibrary','addObserver','setMetadataOptions','logFactory','ImportCandidates'};
folder_depth_bioformats=10;%Folder depth for bioformats to search and calculate the number of datasets
importopt=1; %Inplace import =1;

%Import Packages
java.lang.System.setProperty('java.util.prefs.PreferencesFactory','java.util.prefs.MacOSXPreferencesFactory');
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

%Logging (switch on)
loci.common.DebugTools.enableLogging('INFO');

%Configuration Object
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

finvec=[];
d=dir(pathFolder);
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds= setdiff(nameFolds,{'.','..'});

%Load Omero
client = loadOmero(host);
session = client.createSession(username, password);
client.enableKeepAlive(60);


%Looped Import
wierd_folders=[];spw=[];
for i=1

Projectname = nameFolds{i};
%Metadatastore Object
tic;store = handle(config.createStore());
store.logVersionInfo(config.getIniVersionNumber());t2=toc;
tic;reader = OMEROWrapper(config);t3=toc;

%     diary('log_test_images_good.txt')
paths = [pathFolder Projectname];
tic;handler = handle(ErrorHandler(config));t4=toc;
tic;candidates = handle(ImportCandidates(folder_depth_bioformats,reader, paths, handler));t5=toc;

%Wierd Folder Errors
if ((candidates.getContainers().size)==0)
wierd_folders=[wierd_folders ; i];
continue
end

%Check point 1 : to check if its a SWP(screen/well/plate format)
check_spw = candidates.getContainers().get(0).getIsSPW();
if check_spw.toString.matches('true')
spw=[spw ; i];
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

if j>1 & ~isempty(intersect(DatasetName,datasetvec(:,1)))
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
reader.close();

end
store.logout();store.closeServices();
finvec=[finvec ; timevec];


end
%Logout and close session
store.logout;
client.closeSession();
time1=clock;
save([date '_' num2str(time1(4)) '_' num2str(time1(5)) '_finvec_testimagesgood.mat'],'finvec','nameFolds','spw','wierd_folders','timevar');

