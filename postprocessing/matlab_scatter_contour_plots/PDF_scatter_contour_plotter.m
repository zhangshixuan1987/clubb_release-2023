% $Id$
function PDF_scatter_contour_plotter( input_file_sam, input_file_clubb )

% SAM LES 3D NetCDF filename.
if ( strcmp( input_file_sam, 'default' ) )
   filename_sam = '../../output/LES_output/RICO_128x128x100_drizzle_128_0000255600_micro.nc';
else
   filename_sam = input_file_sam;
end

% CLUBB zt NetCDF filename.
if ( strcmp( input_file_clubb, 'default' ) )
   filename_clubb = '../../output/rico_zt.nc';
else
   filename_clubb = input_file_clubb;
end

% Declare the CLUBB vertical level index.
% CLUBB contour and line plots will be generated from PDF parameters from
% this level.  SAM LES data will be interpolated to the altitude of this
% level and then displayed in scatterplots and histograms.
clubb_height_idx = 19;

% Information to be printed on the plots.
casename = 'RICO';
print_note = 'Input fields (predictive fields)';

% Select the plots that will be plotted.
plot_chi_eta = true;
plot_w_rr    = true;
plot_w_Nr    = true;
plot_chi_rr  = true;
plot_chi_Nr  = true;
plot_eta_rr  = true;
plot_eta_Nr  = true;
plot_rr_Nr   = true;

%==========================================================================

% SAM LES 3D file variables
global idx_3D_w
global idx_3D_chi
global idx_3D_eta
global idx_3D_rr
global idx_3D_Nr
% CLUBB variables
global idx_w_1
global idx_w_2
global idx_chi_1
global idx_chi_2
global idx_mu_rr_1_n
global idx_mu_rr_2_n
global idx_mu_Nr_1_n
global idx_mu_Nr_2_n
global idx_varnce_w_1
global idx_varnce_w_2
global idx_stdev_chi_1
global idx_stdev_chi_2
global idx_stdev_eta_1
global idx_stdev_eta_2
global idx_sigma_rr_1_n
global idx_sigma_rr_2_n
global idx_sigma_Nr_1_n
global idx_sigma_Nr_2_n
global idx_corr_chi_eta_1_ca
global idx_corr_chi_eta_2_ca
global idx_corr_w_rr_1_n
global idx_corr_w_rr_2_n
global idx_corr_w_Nr_1_n
global idx_corr_w_Nr_2_n
global idx_corr_chi_rr_1_n
global idx_corr_chi_rr_2_n
global idx_corr_chi_Nr_1_n
global idx_corr_chi_Nr_2_n
global idx_corr_eta_rr_1_n
global idx_corr_eta_rr_2_n
global idx_corr_eta_Nr_1_n
global idx_corr_eta_Nr_2_n
global idx_corr_rr_Nr_1_n
global idx_corr_rr_Nr_2_n
global idx_mixt_frac
global idx_precip_frac_1
global idx_precip_frac_2

% Read SAM NetCDF file and obtain variables.
[ z_sam, time_sam, var_sam, units_corrector_type_sam, ...
  nx_sam, ny_sam, nz_sam, num_t_sam, num_var_sam ] ...
= read_SAM_3D_file( filename_sam );

% Read CLUBB zt NetCDF file and obtain variables.
[ z_clubb, time_clubb, var_clubb, units_corrector_type_clubb, ...
  nz_clubb, num_t_clubb, num_var_clubb ] ...
= read_CLUBB_file( filename_clubb );

% Use appropriate units (SI units).
[ var_sam ] ...
   = unit_corrector( num_var_sam, var_sam, units_corrector_type_sam, -1 );
[ var_clubb ] ...
   = unit_corrector( num_var_clubb, var_clubb, ...
                     units_corrector_type_clubb, -1 );

% Find the time in the CLUBB zt output file that is equal (or closest) to
% the SAM LES output time.
time_sam_sec = time_sam * 86400.0;
time_diff_clubb_sam_sec = abs( time_clubb - time_sam_sec );
% Initialize the minimum time difference and its (CLUBB) index.
idx_min_time_diff = 1;
min_time_diff = time_diff_clubb_sam_sec(idx_min_time_diff);
% Find the index of the minimum time difference between CLUBB output time
% and the requested SAM 3D file output time.
for iter = 2:1:num_t_clubb
   if ( time_diff_clubb_sam_sec(iter) < min_time_diff )
      min_time_diff = time_diff_clubb_sam_sec(iter);
      idx_min_time_diff = iter;
   end
end
% The CLUBB output index is the index that corresponds with the minimum
% time difference between the CLUBB output time and the SAM LES 3D file
% output time.
clubb_time_idx = idx_min_time_diff;

% Print the time of the SAM LES output.
fprintf( 'Time of SAM LES output (seconds): %d\n', time_sam_sec );

% Print the CLUBB output time index and the associated time.
fprintf( [ 'Time index of CLUBB output: %d;', ...
           ' Time of CLUBB output (seconds): %d\n' ], ...
           clubb_time_idx, time_clubb(clubb_time_idx) );

% Print the altitude at the CLUBB vertical level index.
fprintf( 'Altitude of CLUBB zt grid level (meters): %d\n', ...
         z_clubb(clubb_height_idx) );

% Place the SAM variables from the same location in the same 1-D index for
% use in a scatterplot.
sam_var_lev = zeros( num_var_sam, nx_sam*ny_sam );

if ( z_clubb(clubb_height_idx) > z_sam(nz_sam) )

   % The height of the CLUBB grid level is above the highest SAM LES grid
   % level.  Use SAM values from the highest SAM LES grid level.
   fprintf( [ 'The altitude of the CLUBB zt grid level is higher ', ...
              'than the highest SAM LES grid level.  The highest ', ...
              'SAM LES grid level will be used.\n' ] );
   fprintf( 'Altitude of SAM LES grid level (meters): %d\n', ...
            z_sam(nz_sam) );

   for i = 1:1:nx_sam
      for j = 1:1:ny_sam
         for idx_var = 1:1:num_var_sam
            sam_var_lev(idx_var,(i-1)*ny_sam+j) ...
            = var_sam(idx_var,i,j,nz_sam,1);
         end % idx_var = 1:1:num_var_sam
      end % j = 1:1:ny_sam
   end % i = 1:1:nx_sam

elseif ( z_clubb(clubb_height_idx) < z_sam(1) )
         
   % The height of the CLUBB grid level is below the lowest SAM LES grid
   % level.  Use SAM values from the lowest SAM LES grid level.
   fprintf( [ 'The altitude of the CLUBB zt grid level is lower ', ...
              'than the lowest SAM LES grid level.  The lowest ', ...
              'SAM LES grid level will be used.\n' ] );
   fprintf( 'Altitude of SAM LES grid level (meters):  %d\n', ...
            z_sam(1) );

   for i = 1:1:nx_sam
      for j = 1:1:ny_sam
         for idx_var = 1:1:num_var_sam
            sam_var_lev(idx_var,(i-1)*ny_sam+j) = var_sam(idx_var,i,j,1,1);
         end % idx_var = 1:1:num_var_sam
      end % j = 1:1:ny_sam
   end % i = 1:1:nx_sam

else % z_sam(1) <= z_clubb(clubb_height_idx) <= z_sam(nz_sam)

   % The height of the CLUBB grid level is found within the SAM LES
   % vertical domain.
   exact_lev_idx = -1;
   lower_lev_idx = -1;
   upper_lev_idx = -1;
   for k = 1:1:nz_sam

      if ( z_sam(k) == z_clubb(clubb_height_idx) )

         % The SAM LES grid level is at the exact same altitude as the
         % requested CLUBB grid level.
         exact_lev_idx = k;
         break

      elseif ( z_sam(k) < z_clubb(clubb_height_idx) )

         % The SAM LES grid level is below the requested CLUBB grid level.
         lower_lev_idx = k;

      else % z_sam(k) > z_clubb(clubb_height_idx)

         % The SAM LES grid level is above the requested CLUBB grid level.
         upper_lev_idx = k;

      end

      if ( upper_lev_idx == lower_lev_idx + 1 )
         break
      end

   end % k = 1:1:nz_sam

   if ( exact_lev_idx > 0 )

      fprintf( [ 'The altitude of the SAM LES grid level is the same ', ...
                 'as the CLUBB zt grid level.\n' ] );

      for i = 1:1:nx_sam
         for j = 1:1:ny_sam
            for idx_var = 1:1:num_var_sam
               sam_var_lev(idx_var,(i-1)*ny_sam+j) ...
               = var_sam(idx_var,i,j,exact_lev_idx,1);
            end % idx_var = 1:1:num_var_sam
         end % j = 1:1:ny_sam
      end % i = 1:1:nx_sam

   else % interpolate between two levels.
 
      interp_weight ...
      = ( z_clubb(clubb_height_idx) - z_sam(lower_lev_idx) ) ...
        / ( z_sam(upper_lev_idx) - z_sam(lower_lev_idx) );

      fprintf( [ 'The altitude of the CLUBB zt grid level is between ', ...
                 'two SAM LES grid levels.\n' ] );
      fprintf( [ 'Altitude of the SAM LES grid level above the ', ...
                 'CLUBB zt grid level (meters):  %d\n' ], ...
                 z_sam(upper_lev_idx) );
      fprintf( [ 'Altitude of the SAM LES grid level below the ', ...
                 'CLUBB zt grid level (meters):  %d\n' ], ...
                 z_sam(lower_lev_idx) );

      for i = 1:1:nx_sam
         for j = 1:1:ny_sam
            for idx_var = 1:1:num_var_sam

               sam_var_lev(idx_var,(i-1)*ny_sam+j) ...
               = interp_weight ...
                 * var_sam(idx_var,i,j,upper_lev_idx,1) ...
                 + ( 1.0 - interp_weight ) ...
                   * var_sam(idx_var,i,j,lower_lev_idx,1);

            end % idx_var = 1:1:num_var_sam
         end % j = 1:1:ny_sam
      end % i = 1:1:nx_sam

   end % exact_lev_idx > 0

end % z_clubb(clubb_height_idx)

%==========================================================================

% Unpack CLUBB variables (PDF parameters).

% PDF component means.
mu_w_1 = var_clubb( idx_w_1, 1, 1, clubb_height_idx, clubb_time_idx );
mu_w_2 = var_clubb( idx_w_2, 1, 1, clubb_height_idx, clubb_time_idx );
mu_chi_1 = var_clubb( idx_chi_1, 1, 1, clubb_height_idx, clubb_time_idx );
mu_chi_2 = var_clubb( idx_chi_2, 1, 1, clubb_height_idx, clubb_time_idx );
mu_eta_1 = 0.0; % The component mean of eta is always defined as 0.
mu_eta_2 = 0.0; % The component mean of eta is always defined as 0.
mu_rr_1_n = var_clubb( idx_mu_rr_1_n, 1, 1, ...
                       clubb_height_idx, clubb_time_idx );
mu_rr_2_n = var_clubb( idx_mu_rr_2_n, 1, 1, ...
                       clubb_height_idx, clubb_time_idx );
mu_Nr_1_n = var_clubb( idx_mu_Nr_1_n, 1, 1, ...
                       clubb_height_idx, clubb_time_idx );
mu_Nr_2_n = var_clubb( idx_mu_Nr_2_n, 1, 1, ...
                       clubb_height_idx, clubb_time_idx );

% PDF component standard deviations.
sigma_w_1 = sqrt( var_clubb( idx_varnce_w_1, 1, 1, ...
                             clubb_height_idx, clubb_time_idx ) );
sigma_w_2 = sqrt( var_clubb( idx_varnce_w_2, 1, 1, ...
                             clubb_height_idx, clubb_time_idx ) );
sigma_chi_1 = var_clubb( idx_stdev_chi_1, 1, 1, ...
                         clubb_height_idx, clubb_time_idx );
sigma_chi_2 = var_clubb( idx_stdev_chi_2, 1, 1, ...
                         clubb_height_idx, clubb_time_idx );
sigma_eta_1 = var_clubb( idx_stdev_eta_1, 1, 1, ...
                         clubb_height_idx, clubb_time_idx );
sigma_eta_2 = var_clubb( idx_stdev_eta_2, 1, 1, ...
                         clubb_height_idx, clubb_time_idx );
sigma_rr_1_n = var_clubb( idx_sigma_rr_1_n, 1, 1, ...
                          clubb_height_idx, clubb_time_idx );
sigma_rr_2_n = var_clubb( idx_sigma_rr_2_n, 1, 1, ...
                          clubb_height_idx, clubb_time_idx );
sigma_Nr_1_n = var_clubb( idx_sigma_Nr_1_n, 1, 1, ...
                          clubb_height_idx, clubb_time_idx );
sigma_Nr_2_n = var_clubb( idx_sigma_Nr_2_n, 1, 1, ...
                          clubb_height_idx, clubb_time_idx );

% PDF component correlations.
corr_chi_eta_1 = var_clubb( idx_corr_chi_eta_1_ca, 1, 1, ...
                            clubb_height_idx, clubb_time_idx );
corr_chi_eta_2 = var_clubb( idx_corr_chi_eta_2_ca, 1, 1, ...
                            clubb_height_idx, clubb_time_idx );
corr_w_rr_1_n = var_clubb( idx_corr_w_rr_1_n, 1, 1, ...
                           clubb_height_idx, clubb_time_idx );
corr_w_rr_2_n = var_clubb( idx_corr_w_rr_2_n, 1, 1, ...
                           clubb_height_idx, clubb_time_idx );
corr_w_Nr_1_n = var_clubb( idx_corr_w_Nr_1_n, 1, 1, ...
                           clubb_height_idx, clubb_time_idx );
corr_w_Nr_2_n = var_clubb( idx_corr_w_Nr_2_n, 1, 1, ...
                           clubb_height_idx, clubb_time_idx );
corr_chi_rr_1_n = var_clubb( idx_corr_chi_rr_1_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_chi_rr_2_n = var_clubb( idx_corr_chi_rr_2_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_chi_Nr_1_n = var_clubb( idx_corr_chi_Nr_1_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_chi_Nr_2_n = var_clubb( idx_corr_chi_Nr_2_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_eta_rr_1_n = var_clubb( idx_corr_eta_rr_1_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_eta_rr_2_n = var_clubb( idx_corr_eta_rr_2_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_eta_Nr_1_n = var_clubb( idx_corr_eta_Nr_1_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_eta_Nr_2_n = var_clubb( idx_corr_eta_Nr_2_n, 1, 1, ...
                             clubb_height_idx, clubb_time_idx );
corr_rr_Nr_1_n = var_clubb( idx_corr_rr_Nr_1_n, 1, 1, ...
                            clubb_height_idx, clubb_time_idx );
corr_rr_Nr_2_n = var_clubb( idx_corr_rr_Nr_2_n, 1, 1, ...
                            clubb_height_idx, clubb_time_idx );

% Other variables involved in the PDF.
mixt_frac = var_clubb( idx_mixt_frac, 1, 1, ...
                       clubb_height_idx, clubb_time_idx );
precip_frac_1 = var_clubb( idx_precip_frac_1, 1, 1, ...
                           clubb_height_idx, clubb_time_idx );
precip_frac_2 = var_clubb( idx_precip_frac_2, 1, 1, ...
                           clubb_height_idx, clubb_time_idx );

%==========================================================================

% Information to be printed on the plots.
print_alt = int2str( round( z_clubb(clubb_height_idx) ) );
print_time = int2str( round( time_clubb(clubb_time_idx) / 60.0 ) );

% When the SAM LES data for rr is 0 everywhere at the level, the plots
% involving rr will fail, causing an exit with an error.  Since these
% plots aren't interesting anyway when there's no rr, simply turn them
% of to avoid the error.
if ( all( sam_var_lev(idx_3D_rr,:) == 0.0 ) )

   fprintf( [ 'The SAM LES values of rr are 0 everywhere at this ', ...
              'level.  Any plots involving rr will be disabled.\n' ] )

   plot_w_rr   = false;
   plot_chi_rr = false;
   plot_eta_rr = false;
   plot_rr_Nr  = false;

end

% When the SAM LES data for Nr is 0 everywhere at the level, the plots
% involving Nr will fail, causing an exit with an error.  Since these
% plots aren't interesting anyway when there's no Nr, simply turn them
% of to avoid the error.
if ( all( sam_var_lev(idx_3D_Nr,:) == 0.0 ) )

   fprintf( [ 'The SAM LES values of Nr are 0 everywhere at this ', ...
              'level.  Any plots involving Nr will be disabled.\n' ] )

   plot_w_Nr   = false;
   plot_chi_Nr = false;
   plot_eta_Nr = false;
   plot_rr_Nr  = false;

end
 
% Plot the CLUBB PDF and LES points for chi and eta.
if ( plot_chi_eta )

   fprintf( 'Plotting scatter/contour plot for chi and eta\n' );

   % The number of w bins/points to plot.
   num_chi_pts = 100;

   % The number of rr bins/points to plot.
   num_eta_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 100;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_NN( sam_var_lev(idx_3D_chi,:), ...
                              sam_var_lev(idx_3D_eta,:), ...
                              nx_sam, ny_sam, ...
                              num_chi_pts, num_eta_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_chi_1, mu_chi_2, mu_eta_1, mu_eta_2, ...
                              sigma_chi_1, sigma_chi_2, sigma_eta_1, ...
                              sigma_eta_2, corr_chi_eta_1, ...
                              corr_chi_eta_2, mixt_frac, ...
                              '\chi    [kg/kg]', '\eta    [kg/kg]', ...
                              [ '\bf ', casename ], '\chi vs. \eta', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_chi_eta_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_chi_eta

% Plot the CLUBB PDF and LES points for w and rr.
if ( plot_w_rr )

   fprintf( 'Plotting scatter/contour plot for w and rr\n' );

   % The number of w bins/points to plot.
   num_w_pts = 100;

   % The number of rr bins/points to plot.
   num_rr_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 50;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_NL( sam_var_lev(idx_3D_w,:), ...
                              sam_var_lev(idx_3D_rr,:), ...
                              nx_sam, ny_sam, ...
                              num_w_pts, num_rr_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_w_1, mu_w_2, mu_rr_1_n, mu_rr_2_n, ...
                              sigma_w_1, sigma_w_2, sigma_rr_1_n, ...
                              sigma_rr_2_n, corr_w_rr_1_n, ...
                              corr_w_rr_2_n, precip_frac_1, ...
                              precip_frac_2, mixt_frac, ...
                              'w    [m/s]', 'r_{r}    [kg/kg]', ...
                              [ '\bf ', casename ], 'w vs. r_{r}', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_w_rr_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_w_rr

% Plot the CLUBB PDF and LES points for w and Nr.
if ( plot_w_Nr )

   fprintf( 'Plotting scatter/contour plot for w and Nr\n' );

   % The number of w bins/points to plot.
   num_w_pts = 100;

   % The number of Nr bins/points to plot.
   num_Nr_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 50;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_NL( sam_var_lev(idx_3D_w,:), ...
                              sam_var_lev(idx_3D_Nr,:), ...
                              nx_sam, ny_sam, ...
                              num_w_pts, num_Nr_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_w_1, mu_w_2, mu_Nr_1_n, mu_Nr_2_n, ...
                              sigma_w_1, sigma_w_2, sigma_Nr_1_n, ...
                              sigma_Nr_2_n, corr_w_Nr_1_n, ...
                              corr_w_Nr_2_n, precip_frac_1, ...
                              precip_frac_2, mixt_frac, ...
                              'w    [m/s]', 'N_{r}    [num/kg]', ...
                              [ '\bf ', casename ], 'w vs. N_{r}', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_w_Nr_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_w_Nr

% Plot the CLUBB PDF and LES points for chi and rr.
if ( plot_chi_rr )

   fprintf( 'Plotting scatter/contour plot for chi and rr\n' );

   % The number of chi bins/points to plot.
   num_chi_pts = 100;

   % The number of rr bins/points to plot.
   num_rr_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 50;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_NL( sam_var_lev(idx_3D_chi,:), ...
                              sam_var_lev(idx_3D_rr,:), ...
                              nx_sam, ny_sam, ...
                              num_chi_pts, num_rr_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_chi_1, mu_chi_2, mu_rr_1_n, mu_rr_2_n, ...
                              sigma_chi_1, sigma_chi_2, sigma_rr_1_n, ...
                              sigma_rr_2_n, corr_chi_rr_1_n, ...
                              corr_chi_rr_2_n, precip_frac_1, ...
                              precip_frac_2, mixt_frac, ...
                              '\chi    [kg/kg]', 'r_{r}    [kg/kg]', ...
                              [ '\bf ', casename ], '\chi vs. r_{r}', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_chi_rr_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_chi_rr

% Plot the CLUBB PDF and LES points for chi and Nr.
if ( plot_chi_Nr )

   fprintf( 'Plotting scatter/contour plot for chi and Nr\n' );

   % The number of chi bins/points to plot.
   num_chi_pts = 100;

   % The number of Nr bins/points to plot.
   num_Nr_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 50;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_NL( sam_var_lev(idx_3D_chi,:), ...
                              sam_var_lev(idx_3D_Nr,:), ...
                              nx_sam, ny_sam, ...
                              num_chi_pts, num_Nr_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_chi_1, mu_chi_2, mu_Nr_1_n, mu_Nr_2_n, ...
                              sigma_chi_1, sigma_chi_2, sigma_Nr_1_n, ...
                              sigma_Nr_2_n, corr_chi_Nr_1_n, ...
                              corr_chi_Nr_2_n, precip_frac_1, ...
                              precip_frac_2, mixt_frac, ...
                              '\chi    [kg/kg]', 'N_{r}    [num/kg]', ...
                              [ '\bf ', casename ], '\chi vs. N_{r}', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_chi_Nr_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_chi_Nr

% Plot the CLUBB PDF and LES points for eta and rr.
if ( plot_eta_rr)

   fprintf( 'Plotting scatter/contour plot for eta and rr\n' );

   % The number of eta bins/points to plot.
   num_eta_pts = 100;

   % The number of rr bins/points to plot.
   num_rr_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 50;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_NL( sam_var_lev(idx_3D_eta,:), ...
                              sam_var_lev(idx_3D_rr,:), ...
                              nx_sam, ny_sam, ...
                              num_eta_pts, num_rr_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_eta_1, mu_eta_2, mu_rr_1_n, mu_rr_2_n, ...
                              sigma_eta_1, sigma_eta_2, sigma_rr_1_n, ...
                              sigma_rr_2_n, corr_eta_rr_1_n, ...
                              corr_eta_rr_2_n, precip_frac_1, ...
                              precip_frac_2, mixt_frac, ...
                              '\eta    [kg/kg]', 'r_{r}    [kg/kg]', ...
                              [ '\bf ', casename ], '\eta vs. r_{r}', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_eta_rr_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_eta_rr

% Plot the CLUBB PDF and LES points for eta and Nr.
if ( plot_eta_Nr )

   fprintf( 'Plotting scatter/contour plot for eta and Nr\n' );

   % The number of eta bins/points to plot.
   num_eta_pts = 100;

   % The number of Nr bins/points to plot.
   num_Nr_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 50;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_NL( sam_var_lev(idx_3D_eta,:), ...
                              sam_var_lev(idx_3D_Nr,:), ...
                              nx_sam, ny_sam, ...
                              num_eta_pts, num_Nr_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_eta_1, mu_eta_2, mu_Nr_1_n, mu_Nr_2_n, ...
                              sigma_eta_1, sigma_eta_2, sigma_Nr_1_n, ...
                              sigma_Nr_2_n, corr_eta_Nr_1_n, ...
                              corr_eta_Nr_2_n, precip_frac_1, ...
                              precip_frac_2, mixt_frac, ...
                              '\eta    [kg/kg]', 'N_{r}    [num/kg]', ...
                              [ '\bf ', casename ], '\eta vs. N_{r}', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_eta_Nr_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_eta_Nr

% Plot the CLUBB PDF and LES points for rr and Nr.
if ( plot_rr_Nr )

   fprintf( 'Plotting scatter/contour plot for rr and Nr\n' );

   % The number of w bins/points to plot.
   num_rr_pts = 100;

   % The number of rr bins/points to plot.
   num_Nr_pts = 100;

   % The number of contours on the scatter/contour plot.
   num_contours = 100;

   % The number of standard deviations used to help find a minimum contour
   % for the scatter/contour plot.
   num_std_devs_min_contour = 2.0;

   plot_CLUBB_PDF_LES_pts_LL( sam_var_lev(idx_3D_rr,:), ...
                              sam_var_lev(idx_3D_Nr,:), ...
                              nx_sam, ny_sam, ...
                              num_rr_pts, num_Nr_pts, num_contours, ...
                              num_std_devs_min_contour, ...
                              mu_rr_1_n, mu_rr_2_n, mu_Nr_1_n, mu_Nr_2_n, ...
                              sigma_rr_1_n, sigma_rr_2_n, sigma_Nr_1_n, ...
                              sigma_Nr_2_n, corr_rr_Nr_1_n, ...
                              corr_rr_Nr_2_n, precip_frac_1, ...
                              precip_frac_2, mixt_frac, ...
                              'r_{r}    [kg/kg]', 'N_{r}    [num/kg]', ...
                              [ '\bf ', casename ], 'r_{r} vs. N_{r}', ...
                              [ 'Time = ', print_time, ' minutes' ], ...
                              [ 'Altitude = ', print_alt, ' meters' ], ...
                              print_note )

   output_filename = [ 'output/', casename, '_rr_Nr_z', ...
                       print_alt, '_t', print_time ];

   print( '-dpng', output_filename );

end % plot_rr_Nr
