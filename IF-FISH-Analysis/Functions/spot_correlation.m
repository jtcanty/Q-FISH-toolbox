% John Canty                                    % Created 09/08/15
% Yildiz Lab

% Extracts a list of drift-corrected coordinates and intensity values from
% a single-cell epifluorescence Z-stack. Also extracts the coordinates from
% analyzed telomere clusters from a STORM movie. Matches the coordinates
% and generates a correlation plot of spot intensity vs cluster size.

% Function calls:
% None

%%---------------Extract Z-stack Ints/Coords ---------------------
% Make sure you are navigated to the Z-stack working directory
% data_list = [x,y, intensity]
clear all;

dirData = dir('roi*.txt');
num = length(dirData);
data_list = [];

% Extract coordinate/intensity data
for i = 1:num
    field = dirData(i);
    fname = field.name;
    
    %if strfind(fname,'roi')
    info = tdfread(fname,'\t');
    ints = info.I;
    xc = info.Xc; 
    yc = info.Yc;
    
    % Convert ROI coordinates to 512x512 coordinates. Remember to save the upper
    % left ROI coordinate in each roi.inf file
    xstart = input(strcat('Input starting x coordinate for roi',num2str(i),': '));
    ystart = input(strcat('Input starting y coordinate for roi',num2str(i),': '));
    xc_norm = xstart + xc;
    yc_norm = ystart + yc;
    data = horzcat(xc_norm,yc_norm,ints);
    data_list = vertcat(data_list,data);
    
    %else
     %   continue
    %end
end
    
pause 
%%----------------Extract centroid values --------------------------
% Navigate to folder containing clusters generated by STORM
% kmaxcoord_list = [x,y,kval,area,localizations]
clear dirData;
clear num;

kmaxcoord_list = [];
cells = 2;

% Iterate over cell folders
for n = 1:cells
    
    folder = uigetdir;
    cd(folder);
    dirData = dir('roi*.txt');
    num = length(dirData);
    
    % Iterate over roi files
    for i = 1:num
        field = dirData(i);
        fname = field.name;
        if strfind(fname,'output')
            info = dlmread(fname,'\t');
            [kmax,ind] = max(info(:,3));
            data = info(ind,:);
            % Append area and number of localizations from excel file
            fname = strsplit(fname,'_');
            exfile = strcat(char(fname(1)),'.xlsx');
            exdata = xlsread(exfile,'A1:B1');
            ndata = horzcat(data(1:3),exdata);
            kmaxcoord_list = vertcat(kmaxcoord_list,ndata);
        else
            continue
        end
        
    end
end
%%---------------Display values -----------------------------

numkmax = length(kmaxcoord_list);
display(numkmax)

numdata = length(data_list);
display(numdata)

pause

%%---------------Plot coordinates----------------------------
% Plot Z-stack coordinates
cf = figure(1);
set(cf,'Position',[10,10,1500,500]);
s1 = subplot(1,3,1);
x1 = data_list(:,1);
y1 = data_list(:,2);
scatter(x1,y1,'r');
title('Z-stack coordinates');
xlabel(s1,'X');
ylabel(s1,'Y');

% Plot STORM coordinates
s2 = subplot(1,3,2);
x2 = kmaxcoord_list(:,1);
y2 = kmaxcoord_list(:,2);
scatter(x2,y2,'b');
title('STORM coordinates');
xlabel(s2,'X');
ylabel(s2,'Y');

% Plot both Z-stack and STORM coordinates
s3 = subplot(1,3,3);
scatter(x1,y1,'r');
hold on
scatter(x2,y2,'b');
title('Z-stack and STORM coordinates');
xlabel(s3,'X');
ylabel(s3,'Y');

pause

%%---------------Match coordinate values---------------------
% Calculate Euclidean distances for each point
% sz_int = [x,y,kval,area,localizations, intensity] 
sz_int = [];

% Iterate over Z-stack coordinates
for i = 1:numkmax
    % norm array of Z-stack coord to all STORM coords
    norm = sqrt((data_list(:,1)-kmaxcoord_list(i,1)).^2 + (data_list(:,2)-kmaxcoord_list(i,2)).^2);
    % find min norm
    [min_norm,ind] = min(norm);
    if min_norm < 3
        data = horzcat(kmaxcoord_list(i,:),data_list(ind,3));
        sz_int = vertcat(sz_int,data);
        % Add functionality to remove rows
    else
        continue
    end
end

%%---------------Generate correlation plot--------------------------
x3 = sz_int(:,5);
y3 = sz_int(:,6);
figure(2);
scatter(x3,y3,'filled');
xlabel('Localizations');
ylabel('Intensity');

x4 = sz_int(:,4);
y4 = sz_int(:,6);
figure(3)
scatter(x4,y4,'filled')
xlabel('Area');
ylabel('Intensity');

R3 = corrcoef(x3,y3);
num2str(R3(1,2));
display(strcat('The locs vs int R-value is: ',num2str(R3(1,2))))

R4 = corrcoef(x4,y4);
num2str(R4(1,2));
display(strcat('The area vs. int R-value is: ',num2str(R4(1,2))))