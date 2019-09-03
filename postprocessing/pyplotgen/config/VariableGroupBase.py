"""
:author: Nicolas Strike
:date: Mid 2019
"""
from config import Style_definitions
from src.DataReader import NetCdfVariable
from src.Line import Line
from src.Panel import Panel
from src.VariableGroup import VariableGroup


class VariableGroupBase(VariableGroup):
    """
    This is a panel group used for testing the functionality of pyplotgen.
    It contains a set of common panels being used for representing the majority
    of panels.
    """

    def __init__(self, ncdf_datasets, case, sam_file=None, coamps_file=None, r408_dataset=None):
        """

        :param ncdf_datasets:
        :param case:
        :param sam_file:
        """
        self.name = "base variables"
        self.variable_definitions = [
            {'aliases': ['thlm'], 'sam_calc': self.getThlmSamLine},
            {'aliases': ['rtm', 'qtm'],	 'sam_calc': self.getRtmSamLine},
            {'aliases': ['wpthlp', 'WPTHLP'], 'fallback_func': self.getWpthlpFallback},
            {'aliases': ['wprtp', 'WPRTP', 'wpqtp'], 'fallback_func': self.getWprtpFallback},
            {'aliases': ['cloud_frac', 'cf', 'CLD']},
            {'aliases': ['rcm', 'QCL', 'qcm'], 'sam_conv_factor': 1 / 1000},
            {'aliases': ['wp2', 'W2', 'WP2']},
            {'aliases': ['wp3', 'W3', 'WP3'],	 'sam_name': 'W3'},
            {'aliases': ['thlp2', 'THLP2'], 'fallback_func': self.getThlp2Fallback},
            {'aliases': ['rtp2', 'RTP2', 'qtp2'], 'fallback_func': self.getRtp2Fallback},
            {'aliases': ['rtpthlp', 'RTPTHLP', 'qtpthlp'], 'fallback_func': self.getRtpthlpFallback},
            {'aliases': ['rtp3', 'RTP3', 'qtp3'], 'fallback_func': self.getRtp3Fallback},
            {'aliases': ['thlp3', 'THLP3']},
            {'aliases': ['Skw_zt'],	 'sam_calc': self.getSkwZtLesLine, 'coamps_calc': self.getSkwZtLesLine, 'fill_zeros':True},
            {'aliases': ['Skrt_zt'],	 'sam_calc': self.getSkrtZtLesLine, 'coamps_calc': self.getSkrtZtLesLine, 'fill_zeros': True},
            {'aliases': ['Skthl_zt'],	 'sam_calc': self.getSkthlZtLesLine, 'coamps_calc': self.getSkthlZtLesLine, 'fill_zeros': True},
            {'aliases': ['wm', 'WOBS', 'wlsm']},
            {'aliases': ['um', 'U']},
            {'aliases': ['vm', 'V']},
            {'aliases': ['upwp', 'UW'], 'coamps_calc': self.getUwLesLine}, # TODO coamps eqn wpup + wpup_sgs
            {'aliases': ['vpwp', 'VW']}, # TODO coamps eqn wpvp + wpvp_sgs
            {'aliases': ['up2', 'U2']},
            {'aliases': ['vp2', 'V2']},
            {'aliases': ['rcp2', 'QC2', 'qcp2'], 'sam_conv_factor': 1 / 10 ** 6},
            {'aliases': ['lwp', 'CWP'],	 'type': Panel.TYPE_TIMESERIES, 'sam_conv_factor': 1/1000},
            {'aliases': ['wp2_vert_avg', 'CWP'], 'type': Panel.TYPE_TIMESERIES,	 'fill_zeros': True},
            {'aliases': ['tau_zm'], 'fill_zeros': True},
            {'aliases': ['Lscale'], 'fill_zeros': True},
            {'aliases': ['wpthvp', 'WPTHVP'], 'fallback_func': self.getWpthvpFallback},
            {'aliases': ['radht', 'RADQR'], 'sam_conv_factor': 1 / 86400},
            {'aliases': ['rtpthvp', 'RTPTHVP', 'qtpthvp']},
            {'aliases': ['corr_w_chi_1'], 'fill_zeros': True},
            {'aliases': ['corr_chi_eta_1'], 'fill_zeros': True},
            {'aliases': ['thlpthvp', 'THLPTHVP']},

            # TODO SAM output for these variables
            {'aliases': ['rc_coef_zm * wprcp'],	 'fallback_func': self.get_rc_coef_zm_X_wprcp_clubb_line,
                'sam_calc': self.get_rc_coef_zm_X_wprcp_sam_line,
                'title': 'Contribution of Cloud Water Flux to wpthvp',	 'axis_title': 'rc_coef_zm * wprcp [K m/s]'},	 # TODO coamps eqn wpqcp .* (2.5e6 ./ (1004.67*ex0) - 1.61*thvm)
            {'aliases': ['rc_coef_zm * thlprcp'],	 'fallback_func': self.get_rc_coef_zm_X_thlprcp_clubb_line,
                'title': 'Contribution of Cloud Water Flux to thlprcp',	 'axis_title': 'rc_coef_zm * thlprcp [K^2]'},	 # TODO coamps eqn thlpqcp .* (2.5e6 ./ (1004.67*ex0) - 1.61*thvm)
            {'aliases': ['rc_coef_zm * rtprcp'],	 'fallback_func': self.get_rc_coef_zm_X_rtprcp_clubb_line,
                'title': 'Contribution of Cloud Water Flux to rtprcp',	 'axis_title': 'rc_coef_zm * rtprcp [kg/kg K]'}	 # TODO coamp eqn qtpqcp .* (2.5e6 ./ (1004.67*ex0) - 1.61*thvm)

            # TODO rc_coev * wp2rcp


            # TODO corr chi 2's
        ]
        super().__init__(ncdf_datasets, case, sam_file=sam_file, coamps_file=coamps_file, r408_dataset=r408_dataset)

    def getThlmSamLine(self):
        """
        Calculates thlm values from sam output using
        the following equation
        (THETAL + 2500.4.*(THETA./TABS).*(QI./1000))
        :return: requested variable data in the form of a list. Returned data is already cropped to the appropriate min,max indices
        """
        z = self.__getVarForCalculations__('z', self.sam_file)
        thetal = self.__getVarForCalculations__('THETAL', self.sam_file)
        theta = self.__getVarForCalculations__('THETA', self.sam_file)
        tabs = self.__getVarForCalculations__('TABS', self.sam_file)
        qi = self.__getVarForCalculations__('QI', self.sam_file, fill_zeros=True)

        thlm = thetal + (2500.4 * (theta / tabs) * (qi / 1000))

        thlm_line = Line(thlm, z, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return thlm_line

    def getRtmSamLine(self):
        """
        Calculates rtm values from sam output using
        the following equation
        (QT-QI) ./ 1000
        :return: requested variable data in the form of a list. Returned data is already cropped to the appropriate min,max indices
        """
        z = self.__getVarForCalculations__('z', self.sam_file)

        qt = self.__getVarForCalculations__('QT', self.sam_file)
        qi = self.__getVarForCalculations__('QI', self.sam_file, fill_zeros=True)

        rtm = (qt - qi) / 1000

        rtm_line = Line(rtm, z, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return rtm_line

    def getSkwZtLesLine(self):
        """
        Calculates Skw_zt values from sam output using
        the following equation
        WP3 ./ (WP2 + 1.6e-3).^1.5
        :return: requested variable data in the form of a list. Returned data is already cropped to the appropriate min,max indices
        """
        dataset = None
        if self.sam_file is not None:
            dataset = self.sam_file
            line_format = Style_definitions.LES_LINE_STYLE
            label = Style_definitions.SAM_LABEL

        if self.coamps_file is not None:
            dataset = self.coamps_file['sm']
            line_format = Style_definitions.LES_LINE_STYLE
            label = 'COAMPS-LES'

        z = self.__getVarForCalculations__(['z', 'lev', 'altitude'], dataset)
        wp3 = self.__getVarForCalculations__(['WP3', 'W3', 'wp3'], dataset)
        wp2 = self.__getVarForCalculations__(['WP2', 'W2', 'wp2'], dataset)

        skw_zt = wp3 / (wp2 + 1.6e-3) ** 1.5

        skw_zt_line = Line(skw_zt, z, line_format=line_format, label=label)
        return skw_zt_line

    def getSkrtZtLesLine(self):
        """
        Calculates Skrt_zt values from sam output using
        the following equation
         sam eqn RTP3 ./ (RTP2 + 4e-16).^1.5
         coamps eqn qtp3 ./ (qtp2 + 4e-16).^1.5
         :return: requested variable data in the form of a list. Returned data is already cropped to the appropriate min,max indices
        """
        dataset = None
        if self.sam_file is not None:
            dataset = self.sam_file
            line_format = Style_definitions.LES_LINE_STYLE
            label = Style_definitions.SAM_LABEL

        if self.coamps_file is not None:
            dataset = self.coamps_file['sm']
            line_format = Style_definitions.LES_LINE_STYLE
            label = 'COAMPS-LES'

        z = self.__getVarForCalculations__(['z', 'lev', 'altitude'], dataset)
        rtp3 = self.__getVarForCalculations__(['RTP3', 'qtp3'], dataset)
        rtp2 = self.__getVarForCalculations__(['RTP2', 'qtp2'], dataset)
        skrtp_zt = rtp3 / (rtp2 + 4e-16) ** 1.5

        skrtp_zt_line = Line(skrtp_zt, z, line_format=line_format, label=label)
        return skrtp_zt_line

    def getSkthlZtLesLine(self):
        """
        Calculates Skthl_zt values from sam output using
        the following equation
        sam THLP3 ./ (THLP2 + 4e-4).^1.5
        coamps eqn thlp3 ./ (thlp2 + 4e-4).^1.5
         :return: requested variable data in the form of a list. Returned data is already cropped to the appropriate min,max indices
        """
        dataset = None
        if self.sam_file is not None:
            dataset = self.sam_file
            line_format = Style_definitions.LES_LINE_STYLE
            label = Style_definitions.SAM_LABEL

        if self.coamps_file is not None:
            dataset = self.coamps_file['sm']
            line_format = Style_definitions.LES_LINE_STYLE
            label = 'COAMPS-LES'

        z = self.__getVarForCalculations__(['z', 'lev', 'altitude'], dataset)
        thlp3 = self.__getVarForCalculations__(['THLP3', 'thlp3'], dataset)
        thlp2 = self.__getVarForCalculations__(['THLP2', 'thlp2'], dataset)

        skthl_zt = thlp3 / (thlp2 + 4e-16) ** 1.5

        skthl_zt_line = Line(skthl_zt, z, line_format=line_format, label=label)
        return skthl_zt_line

    def getWpthlpFallback(self, dataset_override = None):
        """
        This gets called if WPTHLP isn't outputted in an nc file as a backup way of gathering the data for plotting.
        WPTHLP = (TLFLUX) ./ (RHO * 1004)
        :return:
        """
        z = self.__getVarForCalculations__(['z'], self.sam_file)
        tlflux = self.__getVarForCalculations__(['TLFLUX'], self.sam_file)
        rho = self.__getVarForCalculations__(['RHO'], self.sam_file)

        wpthlp = tlflux / (rho * 1004)

        wpthlp = Line(wpthlp, z, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return wpthlp

    def getWprtpFallback(self, dataset_override = None):
        """
        This gets called if WPRTP isn't outputted in an nc file as a backup way of gathering the data for plotting.
        WPRTP = (QTFLUX) ./ (RHO * 2.5104e+6)
        :return:
        """
        self.start_time = self.start_time
        self.end_time = self.end_time

        z_ncdf = NetCdfVariable('z', self.sam_file, 1)

        qtflux_ncdf = NetCdfVariable('QTFLUX', self.sam_file, 1, start_time=self.start_time, end_time=self.end_time)
        qtflux_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        qtflux = qtflux_ncdf.data

        rho_ncdf = NetCdfVariable('RHO', self.sam_file, 1, start_time=self.start_time, end_time=self.end_time)
        rho_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        rho = rho_ncdf.data

        wprtp = qtflux / (rho * 2.5104e+6)

        z_ncdf.constrain(self.height_min_value, self.height_max_value)
        wprtp = Line(wprtp, z_ncdf.data, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return wprtp

    def getWpthvpFallback(self, dataset_override = None):
        """
        This gets called if WPTHVP isn't outputted in an nc file as a backup way of gathering the data for plotting.
        WPTHVP =  (TVFLUX) ./ ( RHO * 1004)
        :return:
        """
        self.start_time = self.start_time
        self.end_time = self.end_time

        z_ncdf = NetCdfVariable('z', self.sam_file, 1)

        tvflux_ncdf = NetCdfVariable('TVFLUX', self.sam_file, 1, start_time=self.start_time, end_time=self.end_time)
        tvflux_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        tvflux = tvflux_ncdf.data

        rho_ncdf = NetCdfVariable('RHO', self.sam_file, 1, start_time=self.start_time, end_time=self.end_time)
        rho_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        rho = rho_ncdf.data

        wpthvp = tvflux / (rho * 1004)

        z_ncdf.constrain(self.height_min_value, self.height_max_value)
        wpthvp = Line(wpthvp, z_ncdf.data, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return wpthvp

    def getThlp2Fallback(self, dataset_override = None):
        """
        This gets called if THLP2 isn't outputted in an nc file as a backup way of gathering the data for plotting.
        THLP2 = TL2
        :return:
        """
        self.start_time = self.start_time
        self.end_time = self.end_time

        z_ncdf = NetCdfVariable('z', self.sam_file, 1)

        tl2_ncdf = NetCdfVariable('TL2', self.sam_file, 1, start_time=self.start_time, end_time=self.end_time)
        tl2_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        tl2 = tl2_ncdf.data

        z_ncdf.constrain(self.height_min_value, self.height_max_value)
        tl2_line = Line(tl2, z_ncdf.data, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return tl2_line

    def getRtpthlpFallback(self, dataset_override = None):
        """
        This gets called if Rtpthlp isn't outputted in an nc file as a backup way of gathering the data for plotting.
        Rtpthlp = TQ
        :return:
        """
        self.start_time = self.start_time
        self.end_time = self.end_time

        z_ncdf = NetCdfVariable('z', self.sam_file, 1)

        tq_ncdf = NetCdfVariable('TQ', self.sam_file, 1, start_time=self.start_time, end_time=self.end_time)
        tq_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        tq2 = tq_ncdf.data

        z_ncdf.constrain(self.height_min_value, self.height_max_value)
        thlp2 = Line(tq2, z_ncdf.data, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return thlp2

    def getRtp2Fallback(self, dataset_override = None):
        """
        This gets called if RTP2 isn't outputted in an nc file as a backup way of gathering the data for plotting.
        THLP2 = QT2 / 1e+6
        :return:
        """
        self.start_time = self.start_time
        self.end_time = self.end_time

        z_ncdf = NetCdfVariable('z', self.sam_file, 1)

        qt2_ncdf = NetCdfVariable('QT2', self.sam_file, 1, start_time=self.start_time, end_time=self.end_time)
        qt2_ncdf.constrain(self.height_min_value, self.height_max_value, data=z_ncdf.data)
        qt2 = qt2_ncdf.data

        rtp2 = qt2 / 1e6

        z_ncdf.constrain(self.height_min_value, self.height_max_value)
        rtp2_line = Line(rtp2, z_ncdf.data, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return rtp2_line

    def getRtp3Fallback(self, dataset_override=None):
        """
        Caclulates Rtp3 output
        rc_coef_zm .* rtprcp

        :return:
        """
        rtp3 = None
        if dataset_override is not None:
            dataset = dataset_override
        else:
            dataset = self.sam_file
        if 'rc_coef_zm' in dataset.variables.keys() and 'rtprcp' in dataset.variables.keys():
            rc_coef_zm = self.__getVarForCalculations__('rc_coef_zm', dataset)
            rtprcp = self.__getVarForCalculations__('rtprcp', dataset)
            rtp3 = rc_coef_zm * (rtprcp)

        elif 'QCFLUX' in dataset.variables.keys():
            QCFLUX = self.__getVarForCalculations__('QCFLUX', dataset)
            RHO = self.__getVarForCalculations__('RHO', dataset)
            PRES = self.__getVarForCalculations__('PRES', dataset)
            THETAV = self.__getVarForCalculations__('THETAV', dataset)
            rtp3 = ((QCFLUX) / (RHO * 2.5104e+6)) * (2.5e6 / (1004.67*((PRES / 1000)**(287.04/1004.67))) - 1.61*THETAV)
        return rtp3

    def get_rc_coef_zm_X_wprcp_clubb_line(self, dataset_override=None):
        """
        Calculates the Contribution of Cloud Water Flux
        to wpthvp using the equation
        rc_coef_zm .* wprcp
        :return: Line representing rc_coef_zm .* wprcp
        """
        z = self.__getVarForCalculations__('altitude', self.ncdf_files['zm'])
        rc_coef_zm = self.__getVarForCalculations__('rc_coef_zm', self.ncdf_files['zm'], fill_zeros=True)
        wprcp = self.__getVarForCalculations__('wprcp', self.ncdf_files['zm'], fill_zeros=True)

        output = rc_coef_zm * wprcp

        output = Line(output, z, line_format=Style_definitions.DEFAULT_LINE_STYLE, label=Style_definitions.DEFAULT_LABEL)
        return output

    def get_rc_coef_zm_X_wprcp_sam_line(self, dataset_override = None):
        """
        Calculates the Contribution of Cloud Water Flux
        to wpthvp for SAM using the equation

        sam eqn WPRCP * (2.5e6 / (1004.67*((PRES / 1000)^(287.04/1004.67))) - 1.61*THETAV)
        :return:
        """

        dataset = self.sam_file
        if dataset_override is not None:
            dataset = dataset_override

        z = self.__getVarForCalculations__('z', dataset)

        WPRCP = self.__getVarForCalculations__('WPRCP', dataset, fill_zeros=True)
        PRES = self.__getVarForCalculations__('PRES', dataset, fill_zeros=True)
        THETAV = self.__getVarForCalculations__('THETAV', dataset, fill_zeros=True)

        output = WPRCP * (2.5e6 / (1004.67*((PRES / 1000)**(287.04/1004.67))) - 1.61*THETAV)

        output = Line(output, z, line_format=Style_definitions.LES_LINE_STYLE, label=Style_definitions.SAM_LABEL)
        return output

    # rc_coef_zm. * thlprcp
    def get_rc_coef_zm_X_thlprcp_clubb_line(self, dataset_override = None):
        """
        Calculates the Contribution of Cloud Water Flux
        to thlprcp using the equation
        rc_coef_zm * thlprcp
        :return: Line representing rc_coef_zm .* thlprcp
        """
        z = self.__getVarForCalculations__('altitude', self.ncdf_files['zm'])
        rc_coef_zm = self.__getVarForCalculations__('rc_coef_zm', self.ncdf_files['zm'])
        thlprcp = self.__getVarForCalculations__('thlprcp', self.ncdf_files['zm'])

        output = rc_coef_zm * thlprcp

        output = Line(output, z, line_format=Style_definitions.DEFAULT_LINE_STYLE, label=Style_definitions.DEFAULT_LABEL)
        return output
    
    def get_rc_coef_zm_X_rtprcp_clubb_line(self, dataset_override = None):
        """
        Calculates the Contribution of Cloud Water Flux
        to rtprcp using the equation
        rc_coef_zm * rtprcp
        :return: Line representing rc_coef_zm .* rtprcp
        """
        z = self.__getVarForCalculations__('altitude', self.ncdf_files['zm'])
        rc_coef_zm = self.__getVarForCalculations__('rc_coef_zm', self.ncdf_files['zm'])
        rtprcp = self.__getVarForCalculations__('rtprcp', self.ncdf_files['zm'])

        output = rc_coef_zm * rtprcp

        output = Line(output, z, line_format=Style_definitions.DEFAULT_LINE_STYLE, label=Style_definitions.DEFAULT_LABEL)
        return output

    def getUwLesLine(self):
        """
        coamps eqn upwp = wpup + wpup_sgs

         :return: requested variable data in the form of a list. Returned data is already cropped to the appropriate min,max indices
        """
        dataset = None

        # Commented out until SAM output is needed for UW
        # if self.sam_file is not None:
        #     dataset = self.sam_file
        #     z_ncdf = NetCdfVariable('z', dataset, 1)
        #     line_format = Style_definitions.LES_LINE_STYLE
        #     label = Style_definitions.SAM_LABEL

        if self.coamps_file is not None:
            dataset = self.coamps_file['sw']
            z_ncdf = self.__getVarForCalculations__('lev', dataset)
            line_format = Style_definitions.LES_LINE_STYLE
            label = 'COAMPS-LES'

        wpup = self.__getVarForCalculations__('wpup', dataset)
        wpup_sgs = self.__getVarForCalculations__('wpup_sgs', dataset)


        upwp = wpup + wpup_sgs
        upwp_line = Line(upwp, z_ncdf.data, line_format=line_format, label=label)
        return upwp_line