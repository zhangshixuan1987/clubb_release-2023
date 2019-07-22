from pyplotgen.Case import Case
from pyplotgen.DataReader import DataReader
from pyplotgen.VariableGroupBase import VariableGroupBase
from pyplotgen.VariableGroupCorrelations import VariableGroupCorrelations
from pyplotgen.VariableGroupIceMP import VariableGroupIceMP
from pyplotgen.VariableGroupKKMP import VariableGroupKKMP
from pyplotgen.VariableGroupLiquidMP import VariableGroupLiquidMP
from pyplotgen.VariableGroupWs import VariableGroupWs


class Case_arm(Case):
    '''

    '''

    name = 'arm'

    def __init__(self, ncdf_files, plot_sam = True):
        '''

        '''
        self.name = Case_arm.name
        sec_per_min = 60
        self.start_time = 481 #* sec_per_min
        self.end_time = 540 #* sec_per_min
        self.height_min_value = 0
        self.height_max_value = 3500
        self.enabled = True
        self.ncdf_files = ncdf_files
        self.blacklisted_variables = []#'rtp3', 'thlp3', 'rtpthvp', 'thlpthvp']
        sam_file = None
        if plot_sam:
            datareader = DataReader()
            sam_file = datareader.__loadNcFile__(
                "/home/nicolas/sam_benchmark_runs/JULY_2017/ARM_96x96x110/GCSSARM_96x96x110_67m_40m_1s.nc")
        base_variables = VariableGroupBase(self.ncdf_files, self, sam_file=sam_file)
        # w_variables = VariableGroupWs(self.ncdf_files, self, sam_file=sam_file)
        # ice_variables = VariableGroupIceMP(self.ncdf_files, self, sam_file=sam_file)
        # liquid_variables = VariableGroupLiquidMP(self.ncdf_files, self, sam_file=sam_file)
        # corr_variables = VariableGroupCorrelations(self.ncdf_files, self, sam_file=sam_file)
        # kk_variables = VariableGroupKKMP(self.ncdf_files, self, sam_file=sam_file)

        self.panel_groups = [base_variables]#, w_variables]
        self.panels = []

        for panelgroup in self.panel_groups:
            for panel in panelgroup.panels:
                self.panels.append(panel)
