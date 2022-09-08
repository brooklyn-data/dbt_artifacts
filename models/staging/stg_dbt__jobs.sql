{{
    config(
        materialized='table'
    )
}}

with data_table as (
    
    select
        *
        
    from (
        values
        ('36a20604aa73222006b3a8092f3fe20d','Production Incremental Github'),
        ('6307af420519a370927308124f56b35d','Production - Jira mart (30 min)'),
        ('f493b86ef5a1f0cee9dd64ba5abd12c1','dbt Observability'),
        ('be45c3fccfbf42ae415affb2a2d95fc6','GitHub Org Signup CI Test'),
        ('6dc53468a6a6c55d3a3fae809727bb06','Continuous Integration (main)'),
        ('e9277b4c7ff99a69b9cc2a7083543612','Manual into dw.dw'),
        ('df934f579f2cfbd5eadc33af86b60a6c','Production tests - codetime.external marts.github (6am)'),
        ('630571ee8e61fb9efaa9786a9de27353','Production - weekly'),
        ('f365c0e4bc0642c916d918d58d764f01','Production (5 minutes)'),
        ('91edf9918caf23ade612be8a563a676b','Continuous Integration (dev)'),
        ('79efa8ab2a570d70cd5a4091a8343ba7','Manual into dw.dw_staging'),
        ('41187a739fda97dda002fc1ec8bac447','Production tests - non marts (12 hours)'),
        ('4579897252fd6d1afe1ff6b4313db6ce','Analytics (4 hours)'),
        ('3dd640b2748772a55c764c54dc8d0a27','Production - GitHub mart (30 mins)'),
        ('7464a0f3bcc0fd653107b9764ba172ea','Production - users mart (30 mins)'),
        ('01b2a470d875b93b22f9029b8ae3eca6','Backfill GitHub metrics'),
        ('8ec6cd52b9ba5eda90beb3ff84688078','GitHub Org Signup'),
        ('dc4c1bb00aaf01e8a147e3ffa0c93be3','GitHub Org Signup CI'),
        ('e5c6c01d58e904d89d1929d2193da101','Whitney local dev'),
        ('edd4b90229084f9b5b42d84b91c69c6b','Org Signup local test'),
        ('b5d4ed6284cf404f7ad152f36da76e6b','Michael local dev')
    ) as table (job_sk, name)

)

select * from data_table
