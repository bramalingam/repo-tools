%Init
clear all;close all;

%Params
host= 'localhost';  %Host address
username = 'root';  %Username for Insight
password = 'test12'; %Password for Insight
DatasetName = 'INMAC384-DAPI-CM-eGFP_59223_1';   %Choose a dataset name, will be assigned to your imported dataset under the root user.
ImageFormat = '.xdce'; %Image format within the source directory
tic
DataForImport = fuf(['/Volumes/ome/data_repo/public/images/HCS/INCELL2000/INMAC384-DAPI-CM-eGFP_59224_1/*' ImageFormat],'detail');%Source Directory
t=toc;
NumFiles=length(DataForImport); %Number of files for Import

%Load Omero
client = loadOmero(host);
session = client.createSession(username, password);
sess_alive=omeroKeepAlive(60);

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
import omero.model.Screen;
import omero.model.Plate;
import ome.services.blitz.repo.*;

%Logging (switch on)
loci.common.DebugTools.enableLogging('DEBUG');

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
config.targetClass.set('omero.model.Plate');
dataset = createPlate(session, DatasetName);
dataID = javaObject('java.lang.Long',dataset.getId().getValue());
% dataID = javaObject('java.lang.Long',51);
config.targetId.set(dataID);

%Metadatastore Object
tic
store = config.createStore();
t11=toc;

tic
store.logVersionInfo(config.getIniVersionNumber());
reader = OMEROWrapper(config);
t22=toc;

%Library Object
tic
library = ImportLibrary(store, reader);
handler = ErrorHandler(config);
library.addObserver(LoggingImportMonitor());
t33=toc;
diary(['log_' DatasetName '.txt']);

%Random dataset generation
% randomsets=randperm(length(DataForImport));
randomsets=DataForImport;
randomsets=randomsets(1:NumFiles);

%Looped Import
timevec=[];errorvec={};
for i=1:length(randomsets)
    tic
    paths = DataForImport{i};
    t1=toc;
    tic
    candidates = ImportCandidates(reader, paths, handler);
    t2=toc;tic
    reader.setMetadataOptions(DefaultMetadataOptions(MetadataLevel.ALL));
    t3=toc;tic
    success = library.importCandidates(config, candidates);
    t4=toc;
    
    log = org.apache.commons.logging.LogFactory.getLog('ome.formats.importer.ImportLibrary');
    templog=log.setLevel(0);errorvec=[errorvec ; randomsets{i} templog]; %#ok<*AGROW>

    timevec=[timevec ; t1 t2 t3 t4];
    disp([i length(DataForImport) t1 t2 t3 t4]);
end
datavec{j}=timevec;
%Logout and close session
store.logout();
client.closeSession()