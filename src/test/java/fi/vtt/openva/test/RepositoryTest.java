package fi.vtt.openva.test;

import static org.assertj.core.api.Assertions.*;

import java.util.List;
import java.util.stream.Collectors;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.SpringRunner;

import fi.vtt.openva.domain.Account;
import fi.vtt.openva.domain.Application;
import fi.vtt.openva.domain.Codevalues;
import fi.vtt.openva.domain.OitypeProperty;
import fi.vtt.openva.repositories.AccountRepository;
import fi.vtt.openva.repositories.RepositoryService;

@RunWith(SpringRunner.class)
@SpringBootTest
@TestPropertySource(locations="classpath:application-test.properties")
@ComponentScan("fi.vtt.openva")
public class RepositoryTest {
 
    @Autowired
    private RepositoryService repositoryService;
    
    
    @Test
    public void testFindApplicationByName() {    
    	String testTitle = "Demo application";
    	Application found = repositoryService.getApplication(testTitle);
        assertThat(found.getTitle()).isEqualTo(testTitle);
    }
   
    
    @Autowired
    private AccountRepository accountRepository;
    @Test
    public void testFindAccountByName() {    
    	String testName = "openvademo";
    	Account account = accountRepository.findByUsername(testName);
    	System.out.println("Username: " + account.getUsername());
        assertThat(account.getUsername()).isEqualTo(testName);
    }
	
    
    @Test
    public void testGetCodeValues() {    
    	String test = "yes_no";
    	List<Codevalues> codevalues = repositoryService.getCodeValues(test);
    	List<String> found = codevalues.stream().map(Codevalues::getTitle).collect(Collectors.toList());	
        assertThat(found).contains("yes") ;
    }
    
    @Test
    public void testGetOneCodeValue() {    
    	String test = "yes_no";
    	String testvalue = "1";
    	List<Codevalues> codevalues = repositoryService.getCodeValuesByCodeValueAndCodesTitle(testvalue, test);
    	List<String> found = codevalues.stream().map(Codevalues::getTitle).collect(Collectors.toList());	
    	assertThat(found).hasSize(1);
        assertThat(found).contains("yes");
    }
    
    
    @Test
    public void testGetOIPropertyTypesByTitle() {    
    	String test = "AE_FO_consumption";
    	List<OitypeProperty> found =  repositoryService.getOIPropertyTypesByTitle(test);
    	assertThat(found).hasSize(1);
        assertThat(found.get(0).getTitle()).isEqualTo(test);
    }
}
