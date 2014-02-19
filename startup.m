clear all;close all;

jarfiles={'/Users/bramalingam/OME/openmicroscopy/target/OMERO.matlab-5.0.0-rc2-DEV-ice35/bioformats_package.jar';...
       '/Users/bramalingam/OME/openmicroscopy/target/repository/blitz-5.0.0-rc2-DEV-ice35.jar';
    '/Users/bramalingam/OME/openmicroscopy/lib/repository/ini4j-0.3.2.jar';
    '/Users/bramalingam/OME/openmicroscopy/components/bioformats/artifacts/ome-xml.jar';
    '/Users/bramalingam/OME/openmicroscopy/target/OMERO.matlab-5.0.0-rc2-DEV-ice35/libs/omero_client.jar'
    };


for i=1:size(jarfiles,1)
    javaaddpath(jarfiles{i});
end
clear all;