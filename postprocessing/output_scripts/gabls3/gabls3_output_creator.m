function[] = gabls3_output_creator()
% GABLS3_OUTPUT_CREATOR This function creates netCDF files required by the GABLS 3 intercomparison. It uses CLUBB output files as source information.
%
%   This file is also meant to be an example for future MATLAB scripts to
%   convert CLUBB output for data submission in netCDF format.
%   Essentially a script for such a conversion will break down into these
%   sections:
%
%       File Input Section -
%           This is where the input files that are to be converted are
%           specified and read into MATLAB.
%
%       Definition Section -
%           This is where netCDF definitions will be written to the output
%           file. This includes information such as variable names,
%           variable attributes, and global attributes.
%
%       Conversion Section -
%           Since the input information produced by CLUBB may not match one
%           for one with the specifications of the output file, this
%           section is needed. Here all conversions of information will
%           occur such as converting temperature into potential
%           temperature.
%
%       Output File Section -
%           This section is respondsible for writing variable data to the
%           output file.
%


% Necessary include
addpath '../../matlab_include/'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   File Input Section
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Source files of the GABLS3 case

% Path of the GrADS input files
scm_path = ['/home/faschinj/projects/experimental/clubb/output/'];

% zt Grid
smfile   = 'gabls3_zt.ctl';

% zm Grid
swfile   = 'gabls3_zm.ctl';

% sfc Grid
sfcfile  = 'gabls3_sfc.ctl';

% Reading the header from zt file
[filename,nz,z,ntimesteps,numvars,list_vars] = header_read([scm_path,smfile]);

% Used to navigate through time in all of the files. At the time this
% script was written, all of the GrADS output files generated by CLUBB used
% the same timestep.
t = 1:ntimesteps;
sizet = ntimesteps;

% Read in zt file's variables into MATLAB.
% Variables will be usable in the form <GrADS Variable Name>_array.
for i=1:numvars
    for timestep = 1:sizet
    	stringtoeval = [list_vars(i,:), ' = read_grads_clubb_endian([scm_path,filename],''ieee-le'',nz,t(timestep),t(timestep),i,numvars);'];
    	eval(stringtoeval);
    	str = list_vars(i,:);
        arraydata(1:nz,timestep) = eval([str,'(1:nz)']);
    	eval([strtrim(str),'_array = arraydata;']);
    end
    disp(i);
end

% Reading the header from zm file
[w_filename,w_nz,w_z,w_ntimesteps,w_numvars,w_list_vars] = header_read([scm_path,swfile]);
 
% Read in zm file's variables into MATLAB.
% Variables will be usable in the form <GrADS Variable Name>_array
for i=1:w_numvars
     for timestep = 1:sizet
         stringtoeval = [w_list_vars(i,:), ' = read_grads_clubb_endian([scm_path,w_filename],''ieee-le'',w_nz,t(timestep),t(timestep),i,w_numvars);'];
         eval(stringtoeval)
         str = w_list_vars(i,:);
         arraydata(1:w_nz,timestep) = eval([str,'(1:w_nz)']);
         eval([strtrim(str),'_array = arraydata;']);
     end
     disp(i);
end

% Reading the header from the sfc file
[sfc_filename,sfc_nz,sfc_z,sfc_ntimesteps,sfc_numvars,sfc_list_vars] = header_read([scm_path,sfcfile]);
 
% Read in sfc file's variables into MATLAB.
% Variables will be usable in the form <GrADS Variable Name>_array
for i=1:sfc_numvars
    for timestep = 1:sizet
        stringtoeval = [sfc_list_vars(i,:), ' = read_grads_clubb_endian([scm_path,sfc_filename],''ieee-le'',sfc_nz,t(timestep),t(timestep),i,sfc_numvars);'];
        eval(stringtoeval)
        str = sfc_list_vars(i,:);
        arraydata(1:sfc_nz,timestep) = eval([str,'(1:sfc_nz)']);
        eval([strtrim(str),'_array = arraydata(1:sfc_nz,:);']);
    end
    disp(i);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Conversion Section
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Perform Necessary conversions
qtm_array = convert_units.total_water_mixing_ratio_to_specific_humidity( rtm_array );
T_forcing_array = convert_units.thlm_f_to_t_f( thlm_f_array, radht_array, exner_array );
ome_array = convert_units.w_wind_in_ms_to_Pas( wm_array, rho_array );
wt_array = convert_units.potential_temperature_to_temperature( wpthlp_array, exner_array );

wq_array = wprtp_array ./ (1 + rtm_array);


time_out = 1:sizet;
for i=1:sizet
    time_out(i) =  i*10.0*60.0;
end

full_z  = convert_units.create_time_height_series( z, sizet );
full_w_z = convert_units.create_time_height_series( w_z, sizet );
full_sfc_z = convert_units.create_time_height_series( sfc_z, sizet );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Definition Section
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create the new file. By default it is in definition mode.
ncid = netcdf.create('gabls3_scm_UWM_CLUBB_v3.nc','NC_WRITE');

% Define Global Attributes

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % General
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% % Reference to the model
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'Reference_to_the_model','Golaz et. al 2002');

% % contact person
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'contact_person','Joshua Fasching (faschinj@uwm.edu)');
 
% % Type of model where the SCM is derived from (climate model, mesoscale
% weather prediction model, regional model) ?
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'type_of_model_where_the_SCM_is_derived_from','Standalone SCM');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Surface Scheme
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% % Is it a force-restore type or a multi-layer type?
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'), ... 
    'Is_it_a_force-restore_type_or_a_multi-layer_type','force-restore');

% %Does it have skin layer?
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'), ...
    'Does_it_have_skin_layer','No');

% %Is there a tile approach?
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'), ...
    'Is_there_a_tile_approach','No');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Turbulence Scheme
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %Turbulence scheme  (e.g., K profile, TKE-l, ...)
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'), ... 
    'Turbulence_scheme',...
    'Higher order closure');

% %Formulation of eddy diffusivity K.
netcdf.putAtt(ncid,netcdf.getConstant('NC_GLOBAL'), ...
    'Formulation_of_eddy_diffusivity_K.', ...
    'No eddy diffusivitiy; fluxes are prognosed');

% % For E-l and Louis-type scheme: give formulation length scale.
% % For K-profile: how is this  profile determined ? (e.g., based on
% Richardson, Brunt-Vaisala frequency (N^2),  Parcel method, other.
netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), ...
    'How_is_this_profile_determined','Parcel method');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Other
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Any other model specific aspects you find relevent for this intercomparison.

% % Any deviation from the prescribed set up that you had to make because
% of the specific structure of your model
netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), ... 
    ['Any_deviation_from_the_prescribed_set_up_that_you_had_to', ...
    'make_because_of_the_specific_structure_of_your_model'], ...
    ['We needed to set the temperature of the top soil layer and', ...
    ' vegetation to match the surface air at the initial time.']);

% Define dimensions

% Output Time
tdimid = netcdf.defdim(ncid,'time', sizet);

% Half Levels (zm)
levhdimid = netcdf.defdim(ncid,'levh', w_nz);

% Full Levels(zt)
levfdimid = netcdf.defdim(ncid,'levf', nz );

% Soil Levels(sfc)
levsdimid = netcdf.defdim(ncid,'levs', sfc_nz);

% Define variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time series output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tvarid = define_variable( 'time' ,'seconds since 2006-07-01 12:00:00', 's', tdimid, ncid );
ldwvarid = define_variable( 'ldw' ,'long wave downward radiation at surface', 'W/m^2', tdimid, ncid );
lupvarid = define_variable( 'lup' ,'long wave upward radiation at surface', 'W/m^2', tdimid, ncid );
qdwvarid = define_variable( 'qdw' ,'short wave downward radiation at surface', 'W/m^2', tdimid, ncid );
qupvarid = define_variable( 'qup' ,'short wave upward radiation at surface', 'W/m^2', tdimid, ncid );
tskvarid = define_variable( 'tsk' ,'temperature skin layer', 'W/m^2', tdimid, ncid );
qskvarid = define_variable( 'qsk' ,'specific humiditiy top of vegetation layer', 'kg/kg', tdimid, ncid );
gvarid = define_variable( 'g' ,'soil heat flux', 'W/m^2', tdimid, ncid );
shfvarid = define_variable( 'shf' ,'sensible heat flux', 'W/m^2', tdimid, ncid );
lhfvarid = define_variable( 'lhf' ,'latent heat flux', 'W/m^2', tdimid, ncid );
ustarvarid = define_variable( 'ustar' ,'surface velocity', 'm/s', tdimid, ncid );
hpblvarid = define_variable( 'hpbl' ,'boundary layer height', 'm', tdimid, ncid );
t2mvarid = define_variable( 't2m' ,'2m temperature', 'K', tdimid, ncid );
q2mvarid =  define_variable( 'q2m' ,'2m specific humidity', 'kg/kg', tdimid, ncid );
u10mvarid = define_variable( 'u10m' ,'10m u-component wind', 'm/s', tdimid, ncid );
v10mvarid =  define_variable( 'v10m' ,'10m v-component wind', 'm/s', tdimid, ncid );
ccvarid = define_variable( 'cc' ,'cloudcover fration', '0 1', tdimid, ncid );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Full/Half Level Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

zfvarid = define_variable( 'zf' ,'height of full level', 'm', [levfdimid tdimid], ncid );
pfvarid = define_variable( 'pf' ,'pressure at full level', 'Pa', [levfdimid tdimid], ncid );
tkvarid = define_variable( 't' ,'temperature', 'K', [levfdimid tdimid], ncid );
thvarid = define_variable( 'th' ,'potential temperature', 'K', [levfdimid tdimid], ncid );
qvarid = define_variable( 'q' ,'specific humidity', 'kg/kg', [levfdimid tdimid], ncid );
uvarid = define_variable( 'u' ,'zonal component wind', 'm/s', [levfdimid tdimid], ncid );
vvarid = define_variable( 'v' ,'meridonal component wind', 'm/s', [levfdimid tdimid], ncid );
ugeovarid = define_variable( 'ugeo' ,'u-component geostrophic wind', 'm/s', [levfdimid tdimid], ncid );
vgeovarid = define_variable( 'vgeo' ,'v-component geostrophic wind', 'm/s', [levfdimid tdimid], ncid );
dudt_lsvarid = define_variable( 'dudt_ls' ,'u-component momentum advection', 'm/s/s', [levhdimid tdimid], ncid );
dvdt_lsvarid = define_variable( 'dvdt_ls' ,'v-component momentum advection', 'm/s/s', [levhdimid tdimid], ncid );
dtdt_lsvarid = define_variable( 'dtdt_ls' ,'temperature advection', 'K/s', [levhdimid tdimid], ncid );
dqdt_lsvarid = define_variable( 'dqdt_ls' ,'specific humidity advection', 'kg/kg/s', [levhdimid tdimid], ncid );
omevarid = define_variable( 'ome' ,'vertical movement', 'Pa/s', [levfdimid tdimid], ncid );
zhvarid = define_variable( 'zh' ,'height of half level', 'm', [levhdimid tdimid], ncid );
phvarid = define_variable( 'ph' ,'pressure at half level', 'Pa', [levhdimid tdimid], ncid );
wtvarid = define_variable( 'wt' ,'vertical temperature flux', 'Km/s', [levhdimid tdimid], ncid );
wqvarid = define_variable( 'wq' ,'vertical moisture flux', 'kg/kg m/s', [levhdimid tdimid], ncid );
uwvarid = define_variable( 'uw' ,'vertical flux u-component', 'm2/s2', [levhdimid tdimid], ncid );
vwvarid = define_variable( 'vw' ,'vertical flux v-component', 'm2/s2', [levhdimid tdimid], ncid );
Kmvarid = define_variable( 'Km' ,'eddy diffusivity momentum', 'm2/s', [levhdimid tdimid], ncid );
Khvarid = define_variable( 'Kh' ,'eddy diffusivity heat', 'm2/s', [levhdimid tdimid], ncid );
TKEvarid = define_variable( 'TKE' ,'turbulent kinetic energy', 'm^2/s^2', [levhdimid tdimid], ncid );
shearvarid = define_variable( 'shear' ,'shear production', 'm2/s3', [levhdimid tdimid], ncid );
buoyvarid = define_variable( 'buoy' ,'buoyancy production', 'm2/s3', [levhdimid tdimid], ncid );
transvarid = define_variable( 'trans' ,'total transport', 'm2/s3', [levhdimid tdimid], ncid );
dissivarid = define_variable( 'dissi' ,'dissipation', 'm2/s3', [levhdimid tdimid], ncid );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Surface Level Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

zsvarid = define_variable( 'zs' ,'height of soil level', 'm', [levsdimid tdimid], ncid );
tsvarid = define_variable( 'ts' ,'soil temperature', 'K', [levsdimid tdimid], ncid );
thsvarid = define_variable( 'ths' ,'soil water content', 'm2/s3', [levsdimid tdimid], ncid );%zeros

netcdf.setFill(ncid,'NC_FILL');

% End definition
netcdf.endDef(ncid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Output File Section
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time Series Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

netcdf.putVar( ncid, tvarid, time_out);
netcdf.putVar( ncid, ldwvarid, Frad_LW_down_array(1,:));
netcdf.putVar( ncid, lupvarid, Frad_LW_up_array(1,:));
netcdf.putVar( ncid, qdwvarid, Frad_SW_down_array(1,:));
netcdf.putVar( ncid, qupvarid, Frad_SW_up_array(1,:));
netcdf.putVar( ncid, shfvarid, sh_array(1,:));
netcdf.putVar( ncid, lhfvarid, lh_array(1,:));
netcdf.putVar( ncid, ustarvarid, ustar_array(1,:));
netcdf.putVar( ncid, t2mvarid, T_in_K_array(1,:));
netcdf.putVar( ncid, q2mvarid, qtm_array(1,:));
netcdf.putVar( ncid, u10mvarid, um_array(2,:));
netcdf.putVar( ncid, v10mvarid, vm_array(2,:));
netcdf.putVar( ncid, ccvarid, cc_array(1,:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mean State Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

netcdf.putVar(ncid,zfvarid,full_z);
netcdf.putVar(ncid,pfvarid,p_in_Pa_array);
netcdf.putVar(ncid,tkvarid,T_in_K_array);
netcdf.putVar(ncid,thvarid,thlm_array);
netcdf.putVar(ncid,qvarid,qtm_array);
netcdf.putVar(ncid,uvarid,um_array);
netcdf.putVar(ncid,vvarid,vm_array);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prescribed forcings Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

netcdf.putVar(ncid,ugeovarid,ug_array);
netcdf.putVar(ncid,vgeovarid,vg_array);
netcdf.putVar(ncid,dudt_lsvarid,um_f_array);
netcdf.putVar(ncid,dvdt_lsvarid,vm_f_array);
netcdf.putVar(ncid,dtdt_lsvarid,T_forcing_array);
netcdf.putVar(ncid,dqdt_lsvarid,rtm_f_array);
netcdf.putVar(ncid,omevarid,ome_array);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fluxes Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

netcdf.putVar(ncid,zhvarid,full_w_z);
netcdf.putVar(ncid,wtvarid,wt_array);
netcdf.putVar(ncid,wqvarid,wq_array);
netcdf.putVar(ncid,uwvarid,upwp_array);
netcdf.putVar(ncid,vwvarid,vpwp_array);
netcdf.putVar(ncid, TKEvarid,em_array);
netcdf.putVar(ncid, shearvarid,shear_array);
netcdf.putVar(ncid, buoyvarid,wp2_bp_array);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Soil Variables Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

netcdf.putVar(ncid,zsvarid,full_sfc_z);
netcdf.putVar(ncid,tsvarid,sfc_soil_T_in_K_array);

% Close file
netcdf.close(ncid);
end

function varid = define_variable( shrt_name, long_name, units, dim_ids, file_id )

varid = netcdf.defVar(file_id, shrt_name, 'NC_FLOAT',dim_ids);
netcdf.putAtt(file_id, varid,'unit',units);
netcdf.putAtt(file_id, varid,'long_name',long_name);

end









