'''
:author: Nicolas Strike
:date: Mid 2019
'''

from pyplotgen.DataReader import NetCdfVariable
from pyplotgen.Panel import Panel
from pyplotgen.VariableGroup import VariableGroup
from pyplotgen.Line import Line


class VariableGroupLiquidMP(VariableGroup):

    def __init__(self, ncdf_datasets, case, sam_file=None):
        '''

        :param ncdf_datasets:
        :param case:
        :param sam_file:
        '''
        self.name = "liquid mp variables"
        # TODO Support fill_zeros
        self.variable_definitions = [
            {'clubb_name': 'Ncm', 'sam_calc': self.getNcmSamLine},
            {'clubb_name': 'Nc_in_cloud'},
            {'clubb_name': 'precip_frac'},
            {'clubb_name': 'rrm', 'sam_name': 'QPL', 'sam_conv_factor': 1 / 1000},
            {'clubb_name': 'Nrm', 'sam_calc': self.getNrmSamLine},
            # {'clubb_name': 'wprrp', 'sam_name': 'WPRRP'},  # Not found in lba case file
            # {'clubb_name': 'wpnrp', 'sam_name': 'WPNRP'},  # Not found in lba case file
            {'clubb_name': 'rwp', 'sam_name': 'RWP', 'sam_conv_factor': 1/1000, 'type': Panel.TYPE_TIMESERIES}

        ]
        super().__init__(ncdf_datasets, case, sam_file)


    def getNcmSamLine(self):
        '''
        Caclulates Nim from sam -> clubb using the equation
        (NC * 1e+6) ./ RHO
        :return:
        '''
        sec_per_min = 60
        sam_start_time = self.start_time # / sec_per_min
        sam_end_time = self.end_time # / sec_per_min

        z_ncdf = NetCdfVariable('z', self.sam_file, 1)

        nc_ncdf = NetCdfVariable('NC', self.sam_file, 1, start_time=sam_start_time, end_time=sam_end_time, fill_zeros=True)
        nc_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        nc = nc_ncdf.data
        rho_ncdf = NetCdfVariable('RHO', self.sam_file, 1, start_time=sam_start_time, end_time=sam_end_time)
        rho_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        rho = rho_ncdf.data

        ncm = (nc * (10 ** 6) / rho)

        z_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        ncm_line = Line(ncm, z_ncdf.data, line_format='k-', label='LES output')
        return ncm_line

    def getNrmSamLine(self):
        '''
        Caclulates Nim from sam -> clubb using the equation
        (NR * 1e+6) ./ RHO
        :return:
        '''
        sec_per_min = 60
        sam_start_time = self.start_time # / sec_per_min
        sam_end_time = self.end_time # / sec_per_min

        z_ncdf = NetCdfVariable('z', self.sam_file, 1)

        nr_ncdf = NetCdfVariable('NR', self.sam_file, 1, start_time=sam_start_time, end_time=sam_end_time, fill_zeros=True)
        nr_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        nr = nr_ncdf.data

        rho_ncdf = NetCdfVariable('RHO', self.sam_file, 1, start_time=sam_start_time, end_time=sam_end_time)
        rho_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        rho = rho_ncdf.data

        nrm = (nr * (10 ** 6) / rho)

        z_ncdf.constrain(self.height_min_value, self.height_max_value)
        nrm_line = Line(nrm, z_ncdf.data, line_format='k-', label='LES output')
        return nrm_line