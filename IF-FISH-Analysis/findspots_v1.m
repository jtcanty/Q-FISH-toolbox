%%                        findspots_v1

% John Canty                                Created: 10/08/15
% Yildiz Lab

% Overview:
%   This code loads images of cells stained for both telomere spots and TIF 
%   spots, locates and determines the intensities of the telomeres, locates 
%   the TIF spots, then determines locations and intensities of telomere
%   spots that colocalize with the TIF spots.

% Inputs for this script are .tif images that contain telomeres in one
% channel and TIF spots in another color channel. Make sure that the
% channels are combined into a single .tif file before running. This code
% is used in conjunction with Insight3.

% Input subroutines:
% tif2dax_function.m - converts .tif to .dax files

% NAVIGATE to working directory containing .tif files before startup first!

global insightExe
global Parameters
global DataPath

disp('findspots_v1.m running...');
%DataPath = strcat(pwd,'\');

%% Step 1 - Calculate background and thresholds

% Convert .tif files to .dax files
dirDataTIF = dir('*.tif');
tif2dax_function(dirDataTIF);

% Calculate average background of all .dax Z-stacks
dirDataINF = dir('*.inf');
num = length(dirDataINF);

% Save average background and min. peak thresholds
bkd_threshold_list = [];
for i = 1:num
    fname = dirDataINF(i).name;
    [min_above,avg_bkd] = cellboundavg_function(fname);
    bkd_threshold_list = vertcat(bkd_threshold_list,[min_above,avg_bkd]);
end

xlswrite('thresholds_avgbkd.xlsx',bkd_threshold_list);

%% Step 2 - Configure Insight3 .ini file and run Insight3

% Make sure the .ini file path is set to where Insight3 is located
%insightExe = 'C:\Users\TweedleDee\Documents\STORM\Software\Insight3\InsightM.exe';
%Parameters = 'C:\Users\TweedleDee\Documents\STORM\Software\Insight3\Insight3.ini';

% Update .ini file before each InsightM execution
for i = 1:num
    % Update .ini file
    set_parameters(bkd_threshold_list(i,1),bkd_threshold_list(i,2));
    % Update dax file name
    FileName = dirDataINF(i).name;
    ind = strfind(FileName,'.');
    FileName(ind+1:end)=[];
    dax = strcat(FileName,'dax');
    daxfile = strcat(DataPath,dax);
    % Call InsightM.exe
    ccall = ['!', insightExe,' "',daxfile,'" ',' "',Parameters,'" '];
    eval(ccall);
end

%% Step 3 - Perform Colocalization Analysis



