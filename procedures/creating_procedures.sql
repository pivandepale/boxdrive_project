
CREATE OR REPLACE PROCEDURE REGISTER_CUSTOMER (
    p_customer_name VARCHAR2,
    p_nip VARCHAR2,
    p_house_number VARCHAR2,
    p_street VARCHAR2,
    p_post_code VARCHAR2,
    p_city VARCHAR2,
    p_province VARCHAR2,
    p_country VARCHAR2,
    p_email VARCHAR2,
    p_contact_number VARCHAR2
)
IS
    v_customer_id NUMBER;
    v_address_id NUMBER;
BEGIN
    IF p_customer_name IS NULL OR p_nip IS NULL OR
       p_house_number IS NULL OR p_street IS NULL OR p_post_code IS NULL OR p_city IS NULL OR
       p_province IS NULL OR p_country IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie wszystkie dane uzupewnione.');
    END IF;

    INSERT INTO address (house_number, street, post_code, city, province, country)
    VALUES (p_house_number, p_street, p_post_code, p_city, p_province, p_country)
    RETURNING address_id INTO v_address_id;

    INSERT INTO customers (customer_name, nip, address_id, email, contact_number)
    VALUES (p_customer_name, p_nip, v_address_id, p_email, p_contact_number)
    RETURNING customer_id INTO v_customer_id;
    COMMIT;
    
--EXCEPTION
--    WHEN DUP_VAL_ON_INDEX THEN
 --       ROLLBACK;
 --       RAISE_APPLICATION_ERROR(-20002, 'Podany NIP juz istnieje');
  --  WHEN OTHERS THEN
  --      ROLLBACK;
END REGISTER_CUSTOMER;
/

CREATE OR REPLACE PROCEDURE add_trucks(
    p_truck_model VARCHAR2,
    p_load_capacity NUMBER,
    p_truck_number VARCHAR2,
    p_insurance_number VARCHAR2
)
IS
    v_truck_id NUMBER;
BEGIN
    SELECT MAX(truck_id)
    INTO v_truck_id
    FROM trucks
    WHERE truck_model = p_truck_model;
    
    IF v_truck_id IS NULL THEN
    INSERT INTO trucks (truck_model, load_capacity, truck_total, truck_available)
        VALUES (p_truck_model, p_load_capacity, 0, 0)
        RETURNING truck_id INTO v_truck_id;
    END IF;
        
    INSERT INTO truck_details (truck_id, truck_status, truck_number, insurance_number, availeble_capacity, routes_executed, km_total_driven)
        VALUES (v_truck_id, 'dostepny', p_truck_number, p_insurance_number, p_load_capacity,  0, 0);
EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Pojazd o takim numerze rejestracyjnym lub numerze ubezpieczenia juz istnieje');
END add_trucks;
/

--dodawanie nowych ci??arówek
CREATE OR REPLACE TRIGGER update_truck_total
AFTER INSERT OR DELETE ON truck_details
FOR EACH ROW
DECLARE
    v_truck_model VARCHAR2(200);
BEGIN
    CASE
        WHEN INSERTING THEN
            UPDATE trucks
            SET truck_total = truck_total + 1, 
                truck_available = truck_available + 1
            WHERE truck_id = :NEW.truck_id
            RETURNING truck_model INTO v_truck_model;
            DBMS_OUTPUT.PUT_LINE('Ciezarowka ' || v_truck_model || ' Zostala dodana do floty pojazdow');
        WHEN DELETING THEN
            UPDATE trucks
            SET truck_total = truck_total - 1, 
                truck_available = truck_available  - 1
            WHERE truck_id = :OLD.truck_id
            RETURNING truck_model INTO v_truck_model;
            DBMS_OUTPUT.PUT_LINE('Ciezarowka ' || v_truck_model || ' Zostala usunieta z floty pojazdow');
        END CASE;
        
END;
/
--drop trigger update_truck_total

--zmiana statusu ciezarowek
CREATE OR REPLACE TRIGGER update_availeble_capacity
BEFORE UPDATE OF availeble_capacity ON truck_details
FOR EACH ROW
BEGIN
    IF :NEW.availeble_capacity = 0 THEN
        :NEW.truck_status := 'zajety';
        UPDATE trucks
        SET truck_available = truck_available - 1
        WHERE truck_id = :NEW.truck_id;
    ELSIF
        :NEW.availeble_capacity > 0 THEN
        :NEW.truck_status := 'dostepny';
        UPDATE trucks
        SET truck_available = truck_available + 1
        WHERE truck_id = :NEW.truck_id;
    END IF;
END;
/




CREATE OR REPLACE PROCEDURE register_cargo(
    p_customer_id NUMBER,
    p_destination_point VARCHAR2,
    p_description VARCHAR2,
    p_gross_weight_kg NUMBER,
    p_specific_instructions VARCHAR2
) IS
    v_order_id NUMBER;
    v_cargo_id NUMBER;
BEGIN

    SELECT MAX(order_id) INTO v_order_id
    FROM orders
    WHERE customer_id = p_customer_id
    AND order_status = 'Przyjete';
    
    IF v_order_id IS NULL THEN
        INSERT INTO orders (customer_id, order_date, order_status)
            VALUES (p_customer_id, TO_DATE (SYSDATE, 'DD-MON-RR HH24:MI:SS'), 'Przyjete')
            RETURNING order_id INTO v_order_id;
    END IF;
    
    INSERT INTO cargo (order_id, registration_date, description, Gross_weight_kg, specific_instructions, status)
        VALUES (v_order_id, TO_DATE (SYSDATE, 'DD-MON-RR HH24:MI:SS'), p_description, p_gross_weight_kg, p_specific_instructions, 'Przyjete')
        RETURNING cargo_id INTO v_cargo_id;
    
    INSERT INTO waybills (loading_point, destination_point, cargo_id, issue_date)
        VALUES('magazyn', p_destination_point, v_cargo_id, TO_DATE (SYSDATE, 'DD-MON-RR HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Number zamówienia:' || v_order_id);
END register_cargo;
/
    

CREATE OR REPLACE PROCEDURE check_order_weight(
    p_order_id IN NUMBER,
    v_total_weight OUT NUMBER,
    v_dedicatet_truck_id OUT  NUMBER
    ) IS 
    v_max_capacity NUMBER := 0;
    v_max_cargo_weight NUMBER;
    v_cargo_id NUMBER;
    v_item_processed NUMBER := 1;
BEGIN
    SELECT MAX(availeble_capacity) INTO v_max_capacity
    FROM truck_details 
    WHERE truck_status = 'dostepny';
    
    v_total_weight := 0;
    WHILE v_total_weight <= v_max_capacity LOOP
        SELECT MAX(Gross_weight_kg) INTO  v_max_cargo_weight
        FROM cargo
        WHERE order_id = p_order_id
        AND status = 'Przyjete'
        AND v_total_weight + Gross_weight_kg <= v_max_capacity;
               
        IF v_max_cargo_weight IS NOT NULL THEN
            v_total_weight := v_total_weight + v_max_cargo_weight;
            UPDATE cargo
            SET status = 'Przydzielony'
            WHERE order_id = p_order_id
            AND status = 'Przyjete'
            AND Gross_weight_kg = v_max_cargo_weight
            AND ROWNUM = 1;   
                           
        ELSE
            SELECT availeble_capacity INTO v_max_capacity
            FROM truck_details 
            WHERE availeble_capacity >= v_total_weight
            AND truck_status = 'dostepny'
            ORDER BY availeble_capacity
            FETCH FIRST 1 ROWS ONLY; 
        
            UPDATE truck_details 
            SET availeble_capacity = v_max_capacity - v_total_weight
            WHERE truck_status = 'dostepny'
            AND availeble_capacity = v_max_capacity
            AND ROWNUM = 1
            RETURNING truck_details_id into v_dedicatet_truck_id;
            EXIT;
        END IF;
            
    END LOOP;
            
END check_order_weight;
/

--################################################

CREATE OR REPLACE PROCEDURE submit_an_order(
    p_customer_id NUMBER,
    p_distance_of_segment NUMBER --dystanc odcinku trasy wybranego zamowienia
) IS
    v_order_id NUMBER;
    v_route_id NUMBER;
    v_dedicated_truck NUMBER;
    v_start_location VARCHAR2(50);
    v_end_location VARCHAR2(50);
    v_total_weight NUMBER;
    v_cargo_count NUMBER;
BEGIN
    BEGIN
        SELECT order_id into v_order_id
        FROM ORDERS
        WHERE customer_id = p_customer_id
        AND order_status = 'Przyjete';
        DBMS_OUTPUT.PUT_LINE('Zamowienie nr: ' || v_order_id || ' zostalo zlozone');
        DBMS_OUTPUT.PUT_LINE(' ');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Nie znalezono zadnych zamowien pod numerem klienta: ' || p_customer_id);
                DBMS_OUTPUT.PUT_LINE(' ');
                RETURN;
    END;

    BEGIN
        SELECT w.destination_point INTO v_end_location
        FROM waybills w
        JOIN cargo c ON c.cargo_id = w.cargo_id
        WHERE c.order_id = v_order_id
        AND c.status = 'Przyjete'
        AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Ladunek zamowienia ' || v_order_id || ' nie znaleziony');
                DBMS_OUTPUT.PUT_LINE(' ');
                RETURN;
    END;  
    check_order_weight(v_order_id , v_total_weight, v_dedicated_truck);
    commit;
    
    SELECT COUNT(cargo_id) INTO v_cargo_count
    FROM cargo
    WHERE order_id = v_order_id
    AND status = 'Przyjete';
    IF v_cargo_count = 0 THEN
        UPDATE orders
        SET order_status = 'zaakceptowane'
        WHERE order_id = v_order_id;
        DBMS_OUTPUT.PUT_LINE('Wszystkie ladunki zostaly przydzielone do ciezarowki z id:' || v_dedicated_truck);
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    ELSE
        DBMS_OUTPUT.PUT_LINE('NIE wszystkie ladunki zostaly przydzielone do jednej ciezarowki. Przsze sprawdzic zamowienie');
        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
    END IF;

    SELECT MAX(route_id) INTO v_route_id
    FROM routes
    WHERE truck_details_id = v_dedicated_truck
    AND delivery_status = 'Ladowanie';
    
    
    IF v_route_id IS NULL THEN
        INSERT INTO routes (route_date, truck_details_id, total_distance, delivery_status)
            VALUES (TO_DATE (SYSDATE, 'DD-MON-RR HH24:MI:SS'), v_dedicated_truck, p_distance_of_segment, 'Ladowanie')
            RETURNING route_id INTO v_route_id;
            
        INSERT INTO route_segments (route_id, order_id, start_location, end_location, segment_distance, total_weight)
            VALUES (v_route_id, v_order_id, 'magazyn', v_end_location, p_distance_of_segment, v_total_weight);
        
    ELSE
        SELECT end_location INTO v_start_location
        FROM route_segments
        WHERE route_id = v_route_id
        ORDER BY route_segment_id DESC
        FETCH FIRST 1 ROWS ONLY;
        
        INSERT INTO route_segments (route_id, order_id, start_location, end_location, segment_distance, total_weight)
            VALUES (v_route_id, v_order_id, v_start_location, v_end_location, p_distance_of_segment, v_total_weight);
            
        UPDATE routes 
        SET total_distance = total_distance + p_distance_of_segment
        WHERE route_id = v_route_id;
        
    END IF;
       
END submit_an_order;
/

CREATE OR REPLACE PROCEDURE route_status_update(
    p_route_id NUMBER,
    p_delivery_status VARCHAR2,
    p_order_status VARCHAR2,
    P_cargo_status VARCHAR2
    
    
) IS
BEGIN
    UPDATE routes
    SET delivery_status = p_delivery_status
    WHERE route_id = p_route_id;
    
    UPDATE orders
    SET order_status = p_order_status
    WHERE order_id IN (
        SELECT rs.order_id
        FROM route_segments rs JOIN orders o ON rs.order_id = o.order_id
        WHERE rs.route_id = p_route_id
        );

    UPDATE cargo
    SET status = P_cargo_status
    WHERE cargo_id IN (
        SELECT cargo_id
        FROM route_segments rs JOIN cargo c ON rs.order_id = c.order_id
        WHERE route_id = p_route_id
    );
    
END route_status_update;
/

CREATE OR REPLACE PROCEDURE confirm_route(
    p_route_id NUMBER
) IS
BEGIN
    --procedura aktualizacji statusów routes, orders, cargo
    route_status_update(p_route_id, 'W trakcie', 'W trakcie', 'W drodze');
END confirm_route;
/

CREATE OR REPLACE PROCEDURE complete_route(
    p_route_id NUMBER
) IS
    v_distance_covered NUMBER(20);
BEGIN
    route_status_update(p_route_id, 'Zakonczone', 'Zakonczone', 'Dostarczone');
    
    UPDATE truck_details td
    SET availeble_capacity = (
        SELECT t.load_capacity
        FROM trucks t
        WHERE td.truck_id = t.truck_id
    ), 
    routes_executed = routes_executed + 1,
    km_total_driven = km_total_driven + (
        SELECT r.total_distance
        FROM routes r
        WHERE r.route_id = p_route_id)
    WHERE td.truck_details_id IN (
        SELECT DISTINCT truck_details_id
        FROM routes r
        WHERE r.route_id = p_route_id
    );
END complete_route;
/

CREATE OR REPLACE PROCEDURE cancel_order(
    p_order_id NUMBER
) IS
BEGIN
    UPDATE orders 
    SET order_status = 'Anulowane'
    WHERE order_id = p_order_id;
END cancel_order;