drop function if exists get_jsonb_keys_recursive(JSONB, text, text);
create or replace function get_jsonb_keys_recursive(i JSONB, p text, d text) returns setof text
    LANGUAGE PLPGSQL as
$$
declare
    r RECORD;
    j JSONB;
BEGIN
    IF jsonb_typeof(i) = 'object' THEN
        FOR r IN SELECT * FROM jsonb_each(i)
            loop
                IF jsonb_typeof(i) = 'object' THEN
                    if p is not null then
                        return query SELECT *
                                     from get_jsonb_keys_recursive(i -> r.key, p || d || r.key,
                                                                   d);
                    else
                        RETURN query SELECT * from get_jsonb_keys_recursive(i -> r.key, r.key, d);
                    end if;
                ELSIF jsonb_typeof(i) = 'array' THEN
                    FOR j IN SELECT * FROM jsonb_array_elements(i)
                        LOOP
                            RETURN query SELECT * from get_jsonb_keys_recursive(j, p, d);
                        END LOOP;
                end if;
            end loop;
    ELSIF jsonb_typeof(i) = 'array' THEN
        FOR j IN SELECT * FROM jsonb_array_elements(i)
            LOOP
                RETURN query SELECT * from get_jsonb_keys_recursive(j, p, d);
            END LOOP;
    ELSE
        IF jsonb_typeof(i) = 'object' THEN
            if p is not null then
                RETURN NEXT p || d || i;
            else
                RETURN NEXT i;
            end if;
        ELSE
            RETURN NEXT p;
        end if;
    end if;
END
$$;


drop function if exists get_jsonb_keys(JSONB, text);
create or replace function get_jsonb_keys(i JSONB, d text DEFAULT '.') returns setof text
    LANGUAGE PLPGSQL as
$$
declare
    r RECORD;
    j JSONB;
BEGIN
    IF jsonb_typeof(i) = 'object' THEN
        FOR r IN SELECT * FROM jsonb_each(i)
            loop
                j = i -> r.key;
                if jsonb_typeof(j) = 'object' OR jsonb_typeof(j) = 'array' THEN
                    return query SELECT * from get_jsonb_keys_recursive(i -> r.key, r.key, d);
                ELSE
                    RETURN NEXT r.key;
                end if;
            end loop;
    ELSIF jsonb_typeof(i) = 'array' THEN
        FOR j IN SELECT * FROM jsonb_array_elements(i)
            LOOP
                RETURN query SELECT * from get_jsonb_keys_recursive(j, null, d);
            END LOOP;
    ELSE
        RETURN NEXT i;
    end if;
END
$$;
