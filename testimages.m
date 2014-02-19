clear all;close all;

mkdir('/Users/bramalingam/Desktop/Test_Screen_Data');

for i=1:100
    
    c2=magic(512);
    if ismember(i,[2:2:100])
        
        c2=c2(:);
        rand1=c2(randperm(length(c2)));
        c2=reshape(rand1,512,512);
    end
    imagesc(c2);
    saveas(gca,['/Users/bramalingam/Desktop/Test_Screen_Data/' num2str(i) '.tiff']);
    close;
end
