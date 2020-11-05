import pandas as pd
import joblib
import logging
import time

def make_path(file, state):
    pass

def read_data(state):
    h = pd.read_sas(make_path('h', state), format='sas7bdat')
    p = pd.read_sas(make_path('p', state), format='sas7bdat')
    g = pd.read_sas(make_path('g', state), format='sas7bdat')
    return (h, p, g)

def do_merges(hpg_tup):
    h, p, g = hpg_tup
    merged = p.merge(h, left_on='HHIDP', right_on='HHIDH', how='left')
    merged = g.merge(merged, left_on='GIDG', right_on='GIDH', how='left')
    return merged


def hh_group(merged):
    size = merged.groupby('HHIDP').size().reset_index()
    return merged.merge(size, on='HHIDP')

def cou_avg_pp(merged):
    merged.groupby('COU')['NPU'].mean()
    return merged
    
def cou_avg_age(merged):
    merged.groupby('COU')['AGE'].mean()
    return merged

    
def run_functions(state):
    logging.info('starting ' + state)
    fxns = [read_data,
            do_merges,
            hh_group,
            cou_avg_pp,
            cou_avg_age]
    prior_output = state
    state_start = time.time()
    for fx in fxns:
        start = time.time()
        prior_output = fx(prior_output)
        stop = time.time()
        logging.info(fx.__name__ + ": " + str(stop - start))
        print(fx.__name__, "done")
    state_stop = time.time()
    logging.info('state total ' + str(state_stop - state_start))
    logging.info('number of records: ' + str(len(prior_output)))

logging.basicConfig(filename='runtime.log', level=logging.INFO)

states = ['KS', 'DE', 'NV']
for st in states:
    run_functions(st) 

'''
logging.info("parallelized with joblib")
p = joblib.Parallel(n_jobs=5, verbose=1, backend='multiprocessing')
jobs = [joblib.delayed(run_functions)(st) for st in states]
p(jobs)
'''



