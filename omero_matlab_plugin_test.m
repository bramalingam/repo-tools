clear all;close all;

%--------------------------------------------------------------------------

%Params
hostname= 'gretzky.openmicroscopy.org.uk';  %Host address
username = 'user-3';  %Username for Insight
imageId= 4484;
password = 'ome'; %Password for Insight

%--------------------------------------------------------------------------

%load client and Image
client = loadOmero(hostname);
session = client.createSession(username, password);
image = getImages(session, imageId);
plane = getPlane(session, image, 0, 0, 0);
datasets  = getDatasets(session);
figure; imshow(plane, []);

%--------------------------------------------------------------------------

%Create Project and extract project ID
Projectname = '5_0_0_matlab_release_testing';
project = createProject(session, Projectname);
projectId = project.getId.getValue();

%--------------------------------------------------------------------------

%Create Dataset and extract dataset ID
dataset = omero.model.DatasetI;
dataset.setName(omero.rtypes.rstring(char('name dataset')));
dataset.setDescription(omero.rtypes.rstring(char('description dataset')));

% Link Dataset and Project
link = omero.model.ProjectDatasetLinkI;
link.setChild(dataset);
link.setParent(omero.model.ProjectI(projectId, false));
session.getUpdateService().saveAndReturnObject(link);

% datasetID= dataset.getId.getValue();

%--------------------------------------------------------------------------

% First create a rectangular shape.
rectangle = createRectangle(0, 0, 10, 20);
% Indicate on which plane to attach the shape
setShapeCoordinates(rectangle, 0, 0, 0);

% First create an ellipse shape.
ellipse = createEllipse(0, 0, 10, 20);
% Indicate on which plane to attach the shape
setShapeCoordinates(ellipse, 0, 0, 0);

% Create the roi.
roi = omero.model.RoiI;
% Attach the shapes to the roi, several shapes can be added.
roi.addShape(rectangle);
roi.addShape(ellipse);

% Link the roi and the image
roi.setImage(omero.model.ImageI(imageId, false));
% Save
iUpdate = session.getUpdateService();
roi = iUpdate.saveAndReturnObject(roi);
% Check that the shape has been added.
numShapes = roi.sizeOfShapes;
for ns = 1:numShapes
   shape = roi.getShape(ns-1);
end
%--------------------------------------------------------------------------
keyboard
%Delete Image/Dataset/Project
deleteImages(session, imageId);
% deleteDatasets(session, datasetId);
deleteProjects(session, projectId);
client.closeSession();

