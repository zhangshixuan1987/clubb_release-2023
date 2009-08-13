% This file is a slightly altered version of function header_read from file
% header_read.m.  The difference between this version and that version is
% that this version reads and outputs the GrADS output timestep length, in
% addition to everything else that the original version read and output.
function [filename,nz,z,t_time_steps,time_step_length,numvars,listofparams] ...
   = header_read_expanded(file_header)
%function [filename,nz,z,t_time_steps,numvars,listofparams] = header_read(file_header)
%function [filename,nz,z,t_time_steps,numvars,listofparams] = header_read(file_header,prefix)
% header_read('les_fire.ctl')
% Opens file and initializes some of the values.  
% Input: file_header       --    The header file provided by moments code
% Output: filename         --    The file containing data to be plotted
%         nz               --    The total number of z levels
%         z                --    The heights in the sounding, in vector form
%         t_time_steps     --    The total number of time steps for the run
%         time_step_length --    The length of the time steps in minutes
%         numvars          --    The total number of variables
%         listofparams     --    The names of all the variables, in vector form

%Hardcode some return values to allow for reading of surface data
z = 0;

fid = fopen(file_header, 'rt');

%Ensure the file will be closed no matter what happens
cleanupHandler = onCleanup(@()fclose(fid));

mline = [];
i = 1;
% While your not at the end of file, will advance line by line through the file.
% Searches keywords to extract needed values from the string using if statements.
%  Once the correct string is found, it chops it down to extract the specific value.

% MJF changes
parsevars = 0;
counter   = 1;
% eMFc


while feof(fid) == 0
   tline = fgetl(fid);
    
    if findstr(tline, 'DSET');
       [remainder_1,tline] = strtok(tline);
       filename = strrep(tline,' ^','');
    end

%  This if searches for the ZDEF string to extract the total number of Z levels
%  The while isempty loop reads in the sounding matrix, and concatenates it to one line.
%  The while ischar loop chops the sounding string, converts to numerical, and assigns it
%  to a vector z.

    if findstr(tline, 'ZDEF');  
       [remainder_1,tline] = strtok(tline);
       [remainder_2,tline] = strtok(tline);
       nz = str2num(remainder_2);
       tline = fgetl(fid);
      
       while isempty(findstr(tline, 'TDEF'));
             mline = [mline ' ' tline];
             tline = fgetl(fid);
       end      
      
       while ischar(mline);
             [z_level, mline] = strtok(mline);
             z_level = str2num(z_level);
             z(i) = z_level;
             i = i+1;
            
             if isempty(mline);
                break
             end
       end
    end  
    
    if findstr(tline, 'TDEF');    
       [remainder_1,tline] = strtok(tline);
       [remainder_2,tline] = strtok(tline);
       [remainder_3,tline] = strtok(tline);
       [remainder_4,tline] = strtok(tline);
       t_time_steps = str2num(remainder_2);
       time_step_length = strrep(tline,'mn','');
       time_step_length = str2num(time_step_length);
    end

% MJF code
    if findstr(tline, 'ENDVARS');
        parsevars = 0;
        break
    end
% eMFc    

% MJF code
% This code pads each variable name with spaces out to 15 characters.
if (parsevars == 1)
        [remainder_1,tline] = strtok(tline);
        varsize    = size(remainder_1);
        varsize    = varsize(2);
%        remainder_1 = [prefix remainder_1]
        while (varsize < 15)
            remainder_1(varsize+1) = ' ';
            varsize    = size(remainder_1);
            varsize    = varsize(2);
        end
        listofparams(counter,1:15) = remainder_1(1:15);
        counter = counter + 1;
    end
% eMFc

    if findstr(tline, 'VARS');
       [remainder_1,tline] = strtok(tline);
       numvars = str2num(tline);
% MJF commented this.
%       break
       parsevars = 1;
% eMFc
    end





end

%fclose(fid);


% --CKB--
