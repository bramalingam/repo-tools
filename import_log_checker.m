clear all;close all;

fid=fopen('/Users/bramalingam/omero/log/omeroinsight.log','r');
blitz_log=textscan(fid,'%s','delimiter','[');

blitz_log=blitz_log{1,1};
blitz_log_temp=strfind(blitz_log,'tif');
blitz_log_temp1=strfind(blitz_log,'INCELL2000');

testcases={'loci.formats.ImageReader','Reading IFDs','Populating metadata','Checking comment style','Populating OME metadata',...
    'ome.scifio.io.Location','INCELL'};

logic1 = ~cellfun(@isempty,blitz_log_temp);
logic2 = ~cellfun(@isempty,blitz_log_temp1);
c3=blitz_log(logic1 & logic2);idx1=find(logic1 & logic2);
c4=blitz_log(idx1(2)-1:idx1(length(idx1)-1)+1);

resvec=[];
for i=1:length(testcases)
    
    logic1=strfind(c4,testcases{i});
    logic1=~cellfun(@isempty,logic1);
    finalvec=[c4(find(logic1)-1) c4(find(logic1)+1)];
    
    if i==7
        finalvec=[c4(find(logic1)-1) c4(find(logic1)+1)];
    end
    
    tempvec1=cell2mat(finalvec(:,1));tempvec2=cell2mat(finalvec(:,2));
    idx1=findstr(':',tempvec1(1,:));idx2=findstr(':',tempvec2(1,:));
    finalvec1=[str2num(tempvec1(:,idx1(1)-2:idx1(1)-1))*3600*60*1000+str2num(tempvec1(:,idx1(1)+1:idx1(2)-1))*60*1000+str2num(tempvec1(:,idx1(2)+1:idx1(2)+2))*1000+str2num(tempvec1(:,idx1(2)+4:idx1(2)+6)),...
        str2num(tempvec2(:,idx1(1)-2:idx1(1)-1))*3600*60*1000+str2num(tempvec2(:,idx1(1)+1:idx1(2)-1))*60*1000+str2num(tempvec2(:,idx1(2)+1:idx1(2)+2))*1000+str2num(tempvec2(:,idx1(2)+4:idx1(2)+6))];%all converted to milli seconds
    testvec=[finalvec1(:,2)-finalvec1(:,1)];
    
    if i==6
        testvec=[testvec(1:2:end) testvec(2:2:end)];
    end
    resvec=[resvec testvec(1:299,:)];
end
