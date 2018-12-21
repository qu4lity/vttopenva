/**
 * 
 */
package fi.vtt.openva.repositories;

import org.springframework.data.repository.CrudRepository;
import org.springframework.transaction.annotation.Transactional;

import fi.vtt.openva.domain.Objectofinterest;
import fi.vtt.openva.domain.OitypeProperty;

/**
 * ObjectofinterestRepository
 * 
 * @author Markus Ylikerälä
 *
 */
@Transactional(readOnly = true, timeout=30)
public interface ObjectofinterestRepository extends CrudRepository<Objectofinterest, Integer> {
	/**
	 * Find by id.
	 *
	 * @param valueOf the value of identifer to be found
	 * @return the oitype property
	 */
	Objectofinterest findById(Integer valueOf);
}
