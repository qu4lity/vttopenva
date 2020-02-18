package fi.vtt.openva.repositories;
 
import org.springframework.data.repository.CrudRepository;
 
import fi.vtt.openva.domain.Account;
 
/**
 * AccountRepository
 * 
 * @author Markus Ylikerälä
 *
 */
public interface AccountRepository extends CrudRepository<Account, Integer> {
 
   Account findByUsername(String name);
 
}