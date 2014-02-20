%Init
clear all;close all;

%Params
host= 'localhost';  %Host address
username = 'root';  %Username for Insight
password = 'Asdfgf;lkjhj1'; %Password for Insight
%Choose a dataset name, will be assigned to your imported dataset under the root user.
ImageFormat = '.tiff'; %Image format within the source directory
pathFolder = ['/Volumes/ome/data_repo/test_images_good/'];%Source Directory

importopt=1; %Inplace import =1;

%Load Omero
client = loadOmero(host);
session = client.createSession(username, password);
client.enableKeepAlive(60);

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
import ome.formats.importer.transfers.AbstractExecFileTransfer;
import ome.formats.importer.transfers.TransferState;
import ome.formats.importer.transfers.SymlinkFileTransfer;
import ome.formats.importer.cli.CommandLineImporter;

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
config.targetClass.set('omero.model.Dataset');

finvec=[];
d=dir(pathFolder);
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds= setdiff(nameFolds,{'.','..'});
%Looped Import

for i=[2 3 24]
    
    tic;Projectname = nameFolds{i};
    project = createProject(session, Projectname);t1=toc; %Create a project
    
    
    %Metadatastore Object
    tic;store = config.createStore();    
    store.logVersionInfo(config.getIniVersionNumber());t2=toc;
    tic;reader = OMEROWrapper(config);t3=toc;
    
    diary('log_test.txt')
    
    paths = [pathFolder Projectname];
    tic;handler = ErrorHandler(config);t4=toc;    
    tic;candidates = ImportCandidates(reader, paths, handler);t5=toc;
    
    %Check point 1 : to check if its a SWP(screen/well/plate format)
    check_spw = candidates.getContainers().get(0).getIsSPW();
    if check_spw.toString.matches('true')
        continue
    end
    
    datasetno=candidates.getContainers().size;
    timevec=[];errorvec={};
    
    candidates_dup=candidates;
    %calculate the files for import
    getfiles=[];dataID=[];
    for j=1:datasetno
        
        
        getfiles=[getfiles ; cell(candidates.getContainers().get(j-1).getUsedFiles)]; %#ok<*AGROW>
        getfile=char(candidates.getContainers.get(j-1).getFile);
        idx1 = strfind(getfile,'/');
        DatasetName = strdiff(getfile(1:idx1(end)-1),[paths '/']);%Slash (/) format for mac as of now, can be generalized later.
        
        if isempty(DatasetName)
            DatasetName = getfile(idx1(end+1):length(getfile));            
        end
        tic;dataset = createDataset(session, DatasetName, project.getId.getValue());t6=toc;
        dataID = javaObject('java.lang.Long',dataset.getId().getValue());
        
        %Library Object
        tic;
        if importopt == 1
            library = ImportLibrary(store, reader, SymlinkFileTransfer);
            else
            library = ImportLibrary(store, reader);            
        end;t7=toc;
        
        tic;library.addObserver(LoggingImportMonitor());t8=toc;
        tic;reader.setMetadataOptions(DefaultMetadataOptions(MetadataLevel.ALL));t9=toc;
        
        tic;log = org.apache.commons.logging.LogFactory.getLog('ome.formats.importer.ImportLibrary');
        log.setLevel(0);t10=toc;
        
        tic;config.targetId.set(dataID);
        success = library.importImage(config, candidates.getContainers.get(j-1).getFile);t11=toc;
        timevec=[timevec ; i datasetno t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11];
                
    end
    finvec=[finvec ; timevec];
    
end
%Logout and close session
store.logout();
client.closeSession();