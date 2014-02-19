%Init
clear all;close all;

%Params
host= 'localhost';  %Host address
username = 'root';  %Username for Insight
password = 'test12'; %Password for Insight
%Choose a dataset name, will be assigned to your imported dataset under the root user.
ImageFormat = '.tiff'; %Image format within the source directory
DataForImport = fuf(['/Users/bramalingam/Desktop/Test_Screen_Data/*' ImageFormat],'detail');%Source Directory
NumFiles=20; %Number of files for Import

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

for importopt=1:2
    %Random dataset generation
    finvec=[];
    for j1=1:NumFiles
        
        NF=NumFiles(j1);
        
        %     Projectname = DataForImport(NF);
        Projectname='Test_inplace';
        project = createProject(session, Projectname); %Create a project
        %     NumFiles2= fuf(
        %     for j2=1:length(NumFiles2)
        
        DatasetName = ['test_images_tiff_' num2str(NF)];
        dataset = createDataset(session, DatasetName, project);
        dataID = javaObject('java.lang.Long',dataset.getId().getValue());
        % dataID = javaObject('java.lang.Long',51);
        config.targetId.set(dataID);
        
        %Metadatastore Object
        store = config.createStore();
        
        store.logVersionInfo(config.getIniVersionNumber());
        reader = OMEROWrapper(config);
        
        %Library Object
        if importopt == 1
            library = ImportLibrary(store, reader, SymlinkFileTransfer);
            Projectname='Inplace_import';
        else
            library = ImportLibrary(store, reader);
            Projectname='Hardfile_import';
        end
        
        handler = ErrorHandler(config);
        library.addObserver(LoggingImportMonitor());
        
        %Random dataset generation
        randomsets=randperm(length(DataForImport));
        randomsets=randomsets(1:NF);
        
        diary('log_test.txt')
        %Looped Import
        timevec=[];errorvec={};
        
        for i=1:length(randomsets)
            tic
            paths = DataForImport{randomsets(i)};
            candidates = ImportCandidates(reader, paths, handler);
            reader.setMetadataOptions(DefaultMetadataOptions(MetadataLevel.ALL));
            success = library.importCandidates(config, candidates);
            
            log = org.apache.commons.logging.LogFactory.getLog('ome.formats.importer.ImportLibrary');
            log.setLevel(0);
            
            timer1=toc;timevec=[timevec ; timer1];
            disp([j1 i length(DataForImport) timer1]);
        end
        
        datavec{j1}=timevec;finvec=[finvec ; mean(timevec) std(timevec)];
    end
    
end
%Logout and close session
store.logout();
client.closeSession()