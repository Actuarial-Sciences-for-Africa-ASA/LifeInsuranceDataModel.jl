select m.ref_version mv, s.ref_version as sv from validityintervals m join validityintervals s 
on m.ref_history = s.ref_history
and m.ref_version != s.ref_version
and m.tsdb_validfrom = s.tsdb_invalidfrom
and tstzrange(m.tsworld_validfrom, m.tsworld_invalidfrom) @> s.tsworld_validfrom
where m.ref_history=9
order by m.id

select min(vi.id) from validityintervals vi
where vi.ref_history=9
group by vi.ref_version
