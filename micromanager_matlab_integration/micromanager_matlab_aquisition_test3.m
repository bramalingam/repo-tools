%Multiple sites imaging
%and image analysis(identifying cells with a circularity index>0.8)
%feedback, based on number of cells, change objective to check assay qc
%and integration to omero 
%Author : Balaji.R

%Help : http://micro-manager.3463995.n2.nabble.com/saving-a-multi-image-file-programmatically-td7578824.html

%Init
clear all;close all;

%Import packages
import org.micromanager.MMStudioMainFrame;
import org.micromanager.acquisition.AcquisitionWrapperEngine;
import ij.io.FileSaver;
import org.micromanager.utils.ImageUtils;
import ij.process.ImageProcessor;
import ij.ImagePlus;

%Create gui object
gui = MMStudioMainFrame(false);

%clear all previous acquisitions
gui.closeAllAcquisitions();
gui.clearMessageWindow();

%Show Gui
f = warndlg('Press ok once config file is loaded', 'Note');
gui.show
drawnow;waitfor(f);

%file locations
acqName = 'test-acq';

rootDirName = '/Applications/Micro-Manager1.4/test/';
mkdir(rootDirName)

%parameters
exposures = [10, 1000];
fields = 6;

%Create objects (Acquisition engine and core object)
mmc = gui.getCore;
acq = gui.getAcquisitionEngine;

%load config
mmc.loadSystemConfiguration ('/Applications/Micro-Manager1.4/MMConfig_demo.cfg');

%Get config's of devices
stage=mmc.getXYStageDevice();
zdrive=mmc.getFocusDevice();

%Get position of X,Y and Z
X1= mmc.getXPosition(stage);
Y1= mmc.getYPosition(stage);
Z1=mmc.getPosition(zdrive); %Manually focus on the first field

%load camera properties
config_groups=mmc.getAvailableConfigGroups();
% read_rate=config_groups.get(5);
objective_turr=mmc.getAvailableConfigs(config_groups.get(4));
light_path=mmc.getAvailableConfigs(config_groups.get(3));
Gain_multipler=config_groups.get(2);
channels=mmc.getAvailableConfigs(config_groups.get(1));
camera_gain=config_groups.get(0);

%Set light path (To camera view)
mmc.setConfig(config_groups.get(3), light_path.get(1));

%stage movement in microns (Field spacing)
rval1=100;rval=X1;

%OMERO Session
%Params
host= 'localhost';  %Host address
username = 'user';  %Username for Insight
password = 'password'; %Password for Insight
folder_depth_bioformats=10;
ProjectName = 'Test';
DatasetName = 'Test1';

%Load Omero
client = loadOmero(host);
session = client.createSession(username, password);
client.enableKeepAlive(60);

%Import type for Omero (1 for Symlink Transfer/inplace-import, any other numeric value for
                        %regular upload)
importopt = 1;

%Image Output Directory and Suffix for Image Name
acqRoot = [pwd '/'];
BrightAcqName = 'Test_Config.tiff';

%Temporary Params
Wells={'A' 'B' 'C' 'D'};
Fields = {'F'};
cntr1=1;resvec=[];cellcntr=0;
for l=1:2

mmc.setXYPosition(stage, rval, Y1);
mmc.waitForDevice(stage);

for k=1:3

if k>1
rval=rval1+mmc.getXPosition(stage);
else
rval=mmc.getXPosition(stage);
end

cntr=1;rvec=[];

mmc.setPosition(zdrive,(Z1));
mmc.setExposure(exposures(1));
mmc.setConfig(config_groups.get(1), channels.get(0));

mmc.setXYPosition(stage, rval, Y1);
mmc.waitForDevice(stage);
mmc.snapImage();

img = mmc.getImage();  % returned as a 1D array of signed integers in row-major order
width = mmc.getImageWidth();
height = mmc.getImageHeight();

%Saving image
proc0 = ImageUtils.makeProcessor(mmc, img);
imgp0 = ImagePlus('',proc0);
fs =  FileSaver(imgp0);
path=[acqRoot Wells{1} '00' num2str(l) Fields{1} '00'  num2str(k) '_' BrightAcqName];
fs.saveAsTiff(path);

if mmc.getBytesPerPixel == 2
pixelType = 'uint16';
else
pixelType = 'uint8';
end

img = typecast(img, pixelType);      % pixels must be interpreted as unsigned integers
img = transpose(reshape(img, [width, height])); % image should be interpreted as a 2D array
img1(:,:,cntr,cntr1) = img;
%         imshow(imadjust(img))
pause(3)

%Upload Image to the OMERO Server
upload_image(path,session,username,password,ProjectName,DatasetName,host,importopt)
cntr1=cntr1+1;


%     [seg_img clustidx]=kmeans(double(img(:)),3,'emptyaction','drop');
%     idx1=find(clustidx==min(clustidx));
%
%     [aa numcells]=bwlabel(bwareaopen(reshape(seg_img==idx1,512,512),15));
%     props = regionprops(aa, 'Area', 'Perimeter');
%     areas = [props.Area];
%     perims = [props.Perimeter];
%     circularities = 4 * pi * areas ./ perims .^ 2; % formula for circularity index
%
%     remidx=find(circularities<=0.80);
%     [finimg numcells]=bwlabel(~ismember(aa,[0 remidx]));
%
%     stagevec(k,:)=[rval Y1 Z1 numcells];

%     cellcntr=cellcntr+numcells;
%     imwrite(img,[rootDirName acqName '_field_'  num2str(k) '.tiff'],'Compression','none')
%     if cellcntr>=70
%         break
%     end

end

end
%Stitch all images together (QC View)
% montage(img1);imcontrast;

% figure;imagesc(stagevec(:,4));caxis([0 100])

% %Move stage to field with minimum cells and change objectives and snap an
% %image
% idx1=find(stagevec(:,4)==min(stagevec(:,4)));
% mmc.setXYPosition(stage, stagevec(idx1,1), Y1);
% mmc.waitForDevice(stage);
% %change objectives line
% curr_obj=objective_turr.get(0);
% mmc.setConfig(config_groups.get(4), curr_obj);
% mmc.snapImage();
% img = mmc.getImage();  % returned as a 1D array of signed integers in row-major order
% width = mmc.getImageWidth();
% height = mmc.getImageHeight();
%
% if mmc.getBytesPerPixel == 2
%     pixelType = 'uint16';
% else
%     pixelType = 'uint8';
% end
%
% img = typecast(img, pixelType);      % pixels must be interpreted as unsigned integers
% img = transpose(reshape(img, [width, height])); % image should be interpreted as a 2D array
% imshow(imadjust(img));title('10x image');