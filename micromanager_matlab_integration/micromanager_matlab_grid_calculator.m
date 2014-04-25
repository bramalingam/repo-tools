function [img_grid] = grid_calculator(x,y,fs,nf,nwx,nwy,xwd,ywd)%ex usage for a 96 well plate,9 fields being imaged with a interfield%distance of 200 microns.% img_grid = grid_calculator(0,0,200,9,12,8,9000,9000);% x: Stage x position% y: Stage y position% fs: Intra-well field spacing% nf: Number of fields per well% nwx: number of wells in the x direction or number of columns in your plate (12 in the case of 96 wells).% nwx: number of wells in the y direction or number of rows in your% plate (12 in the case of 96 wells).% xwd: Centroid to centroid distance between adjacent wells in the x% direction (Inter column spacing).% ywd: Centroid to centroid distance between adjacent wells in the y% direction (Inter row spacing).xgrid=(x-fs*nf):fs:(x+fs*nf);ygrid=(y-fs*nf):fs:(y+fs*nf);resvec=[];for i=1:length(xgrid)    xval=xgrid(i);    for j=1:length(ygrid)        yval=ygrid(j);        resvec=[resvec ; xval yval x y ((x-xval)^2+(y-yval)^2)^0.5];    endend[aa ii]=sort(resvec(:,5)); %#ok<*ASGLU>img_grid=resvec(ii(1:nf),1:2);xvec=repmat([0:xwd:(nwx-1)*xwd]',1,size(img_grid,1))';xa1=repmat(img_grid(:,1),1,size(xvec,2));xvec=xvec+xa1;yvec=repmat(img_grid(:,2),1,size(xvec,2));xvec=reshape(xvec,[],1);yvec=yvec(:);yval=repmat([0:ywd:(nwy-1)*ywd]',1,size(yvec,1))';yval=yval(:);rowvec=[xvec yvec];rowvec=repmat(rowvec,nwy,1);img_grid=[rowvec(:,1) rowvec(:,2)+yval];