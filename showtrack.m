% multi box show track boxes

vid_i = 46;
chunk_name = '00401_00900';
box_i = 1;

seq_name = sprintf('self%05d',vid_i);
imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);
imageList = dir(fullfile(imDir, '*.jpg'));
imFiles = {imageList.name};
clear imageList;

%% for only one box given by box_i
% trackfile = fullfile(imDir,'bboxes',sprintf('%s_%03d.track',chunk_name,box_i));
% trackboxes = dlmread(trackfile);
% 
% for i = 1:10:size(trackboxes,1)
%     imshow(imFiles{i});
%     rectangle('Position',trackboxes(i,:),...
%               'EdgeColor', 'r',...
%               'LineStyle','-');
%     pause(0.03);
% end

%% for all boxes together
trackfilelist = dir(fullfile(imDir, 'bboxes', sprintf('%s*.track',chunk_name)));
trackfiles = {trackfilelist.name};
clear trackfilelist;

trackboxes = zeros(str2num(chunk_name(7:11))-str2num(chunk_name(1:5))+1,4,size(trackfiles,2));
for i = 1:1:size(trackfiles,2)
    file = fullfile(imDir,'bboxes',trackfiles{i});
    trackboxes(:,:,i) = dlmread(file);
end

start_i = str2num(chunk_name(1:5));
end_i = str2num(chunk_name(7:11));
for j = start_i:10:end_i
    imshow(imFiles{j});
    for i = 1:1:size(trackfiles,2)
        rectangle('Position',trackboxes(j-start_i+1,:,i),...
                  'EdgeColor', 'r',...
                  'LineStyle','-');
    end
    pause(0.001);
end