package fi.vtt.openva.test;


import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.junit.Assert.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.CookieResultMatchers.*;

//import org.apache.commons.codec.binary.Base64;
//import org.apache.http.client.HttpClient;
//import org.apache.http.impl.client.HttpClientBuilder;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.json.JacksonJsonParser;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Profile;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.orm.hibernate5.LocalSessionFactoryBean;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.RequestBuilder;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.context.TestConfiguration;

import fi.vtt.openva.controller.VisualizationRESTController;

import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.web.DefaultRedirectStrategy;
import org.springframework.security.web.RedirectStrategy;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;


@RunWith(SpringRunner.class)

//application-test.properties overrides original application.properties
@TestPropertySource("classpath:application-test.properties")

@SpringBootTest
@AutoConfigureMockMvc
@ComponentScan("fi.vtt.openva.controller")
@ComponentScan("fi.vtt.openva.service")
@ComponentScan("fi.vtt.openva.task")
@ComponentScan("fi.vtt.openva.repositories")
@ComponentScan("fi.vtt.openva")
@ComponentScan("fi.vtt.openva.rinterface")





// TestSecurityConfiguration overrides original security configuration	
@ContextConfiguration(classes = TestSecurityConfiguration.class)
public class VisualizationTest {
	
	private static String[] TEST_CASES = {"Histogram","/query/Histogram/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Single timeseries","/query/TimeSeriesOneQuantOneLine/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Box plot","/query/BoxPlot/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Contour","/query/MultiOiContour/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Single value indicator","/query/Sum/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Raw data","/query/Rawdata/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Aux.eng. load percentages","/query/AuxLoadAverageBar/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Data values daily","/query/DailyCount/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Steaming/maneuvering","/query/SailingBar/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Timeperiod hours","/query/TimeperiodHours/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Fuel oil consumption/NM","/query/FuelOilBar/params?oiids=2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Multiple variable timeseries","/query/TimeSeriesNQuantOnePlotPerOi/params?oiids=2&varids=20,66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Scatter plot","/query/Scatterplot/params?oiids=2&varids=20,66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Correlation matrix","/query/CorrelationMatrix/params?oiids=2&varids=88,20,66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Multiple timeseries","/query/TimeSeriesOneQuantOnePlotPerOi/params?oiids=2,3&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "One plot, multiple timeseries","/query/TimeSeriesOneQuantOneLinePerOi/params?oiids=2,2&varids=66&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Binary timeseries","/query/TimeSeriesNominalBinary/params?oiids=3&varids=14&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship",
										  "Bar chart","/query/Barchart/params?oiids=2&varids=14&starttime=2017-09-29 17:49:14&endtime=2017-10-30 18:39:34&timeunit=hour&imagetype=raster&oitype=ship"};
	
	@Autowired
	private MockMvc mockMvc;
	
	@Test
	public void testVisualizations() throws Exception {						
		MockHttpSession session = login();
			
		for (int i = 0; i<TEST_CASES.length; i+=2 ) {
	        System.out.println("Test case: " + TEST_CASES[i]);
			mockMvc.perform(get(TEST_CASES[i+1])
					.session(session)  
					.contentType(MediaType.APPLICATION_JSON))
		    	    .andExpect(status().isOk())
		    	    .andExpect(jsonPath("$.title", is(TEST_CASES[i])));  	
		}            
	}


	private MockHttpSession login() throws Exception {
		RequestBuilder requestBuilder = formLogin().user("openvademo").password("a");
		MvcResult mvcResult = mockMvc.perform(requestBuilder)
	    .andExpect(redirectedUrl("/")).andReturn();
		MockHttpSession session = (MockHttpSession) mvcResult.getRequest().getSession(false);
		return session;
	}

	

}
