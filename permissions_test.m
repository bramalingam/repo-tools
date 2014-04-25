clear all;close all;


%Help : http://www.openmicroscopy.org/community/viewtopic.php?f=6&t=2965
import omero.cmd.Chgrp;

import omero.rtypes.rdouble;
import omero.rtypes.rint;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import omero.cmd.Chgrp;
import omero.grid.Column;
import omero.grid.LongColumn;
import omero.grid.TablePrx;
import omero.model.Channel;
import omero.model.Dataset;
import omero.model.DatasetImageLink;
import omero.model.DatasetImageLinkI;
import omero.model.ExperimenterGroup;
import omero.model.FileAnnotation;
import omero.model.FileAnnotationI;
import omero.model.IObject;
import omero.model.Image;
import omero.model.LogicalChannel;
import omero.model.OriginalFile;
import omero.model.Pixels;
import omero.model.Plate;
import omero.model.PlateAcquisition;
import omero.model.PlateAnnotationLink;
import omero.model.PlateAnnotationLinkI;
import omero.model.PlateI;
import omero.model.Project;
import omero.model.ProjectDatasetLink;
import omero.model.ProjectDatasetLinkI;
import omero.model.Reagent;
import omero.model.Rect;
import omero.model.RectI;
import omero.model.Roi;
import omero.model.RoiAnnotationLink;
import omero.model.RoiAnnotationLinkI;
import omero.model.RoiI;
import omero.model.Screen;
import omero.model.ScreenPlateLink;
import omero.model.ScreenPlateLinkI;
import omero.model.Shape;
import omero.model.StatsInfo;
import omero.model.Well;
import omero.model.WellSample;
import omero.sys.EventContext;
% String perms = "rw----";

%Params
host= 'localhost';  %Host address
username = 'root';  %Username for Insight
password = 'Asdfgf;lkjhj1'; %Password for Insight
%Load Omero
client = loadOmero(host);
session = client.createSession(username, password);
client.enableKeepAlive(60);

%Create Group
GroupName = ('Permission_tester26');
group = omero.model.ExperimenterGroupI();
group.setName(rstring(GroupName));
group.getDetails().setPermissions(omero.model.PermissionsI('rwr---'));
newgroupid = session.getAdminService.createGroup(group);
userGroup = omero.model.ExperimenterGroupI(1,false);
newGroup = omero.model.ExperimenterGroupI(newgroupid, false);
groups = toJavaList([userGroup newGroup]);
map=group.copyGroupExperimenterMap();


%Create User
omeroUsername = 'Random_test9';
experimenter = omero.model.ExperimenterI();
experimenter.setFirstName(rstring('Perm'))
experimenter.setLastName(rstring('test'))
experimenter.setOmeName(rstring(omeroUsername))
session.getAdminService.createExperimenterWithPassword(experimenter, rstring('ome'), group, groups);

 %Create commands to move and create the link in target
% g =targetGroup;
% list = ArrayList();
% list.add(Chgrp('/Dataset', d.getId().getValue(), null, g.getId().getValue()));
% 
% %Prepare request
% all = DoAll();
% all.requests = list;
% 
% handle1 = session.submit(all);
% cb = CmdCallbackI(c, handle1);
% cb.loop(10 * all.requests.length, scalingFactor);


% session.getAdminService.createGroup(group);
% userId = session.getAdminService().getEventContext().userId;
% group= session.getAdminService().getGroup(session.getAdminService.getEventContext.groupId());
% groups = java.util.ArrayList();
% for i = 1:N, groups.add(group); end
% userid=[];
% groupid=[];
